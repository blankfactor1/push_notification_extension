require 'fcm'
module PushNotificationExtension
  class Channel
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
    include Mongoid::Timestamps

    # Channel identifier
    field :name, type: String

    attr_accessible :name

    has_and_belongs_to_many :devices, :class_name => "PushNotificationExtension::Device"

    has_many :messages, :class_name => "PushNotificationExtension::Message", :inverse_of => :channel

    def publish(badge = 0, alert, sound, message_payload)
      ios_notifications     = []
      android_notifications = []
      android_device_tokens = []

      parsed_message_payload = nil
      if message_payload.is_a?(String)
        begin
          parsed_message_payload = JSON.parse(message_payload)
        rescue
          Rails.logger.info "Not able to parse message payload: #{$!.message}. Sending the payload as just {data: <message_payload>}."
          parsed_message_payload = {data: message_payload}
        end
      else
        parsed_message_payload = message_payload
      end

      Rails.logger.info("Push notification devices count: #{devices.count}")
      devices.each do |device|
        Rails.logger.info "Sending message #{message_payload}, with badge number #{badge}, to device #{device.token} of type #{device.type} for channel #{name}"

        if device.ios?
          ios_notitifcation_options = {badge: badge, alert: alert, other: parsed_message_payload}
          ios_notitifcation_options.merge!(sound: sound) if !sound.blank?
          ios_notifications << APNS::Notification.new(device.token, ios_notitifcation_options)
        end

        android_device_tokens << device.token if device.android?
      end

      if Rails.env.production?
        hashed_message_payload = Hash.new
        begin
          # Note that that app icons cannot be modified on the android side. This count will have to be displayed in
          # a widget or from the notification system.
          hashed_message_payload["data"] = parsed_message_payload
          hashed_message_payload["notification"] = { body: alert, badge: badge }
          hashed_message_payload.merge!(sound: sound) if !sound.blank?
        rescue
          Rails.logger.error "Unable to parse the message payload for android: " + $!.message
          Rails.logger.error $!.backtrace.join("\n")
        end

        unless hashed_message_payload.nil?
          if AP::PushNotificationExtension::PushNotification.config[:fcm_server_key]
            fcm = ::FCM.new(AP::PushNotificationExtension::PushNotification.config[:fcm_server_key])
            unless android_device_tokens.empty?
              fcm_result = fcm.send(android_device_tokens, hashed_message_payload)
              Rails.logger.info "Channel #{self.name}: Android FCM push status: #{fcm_result}"
            else
              Rails.logger.info "Channel #{self.name}: There are no device tokens available for Android FCM."
            end
          end
        end

        Rails.logger.info("ios notifications count: #{ios_notifications.count}")
        ios_notifications.each do |ios_notification|
          APNS.send_notifications([ios_notification])
        end

        self.messages << Message.new(alert: alert, badge: badge, message_payload: message_payload)
      else
        Rails.logger.info "Notifications will only be sent out for a production environment."
      end
    end

  end
end
