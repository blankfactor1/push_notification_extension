require 'fcm'
require 'apnotic'
module PushNotificationExtension
  class Channel
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document

    before_create :set_timestamps

    # Channel identifier
    field :name, type: String
    # add timestamp fields manually to avoid undefined method `to_datetime' for false:FalseClass
    field :updated_at, type: DateTime
    field :created_at, type: DateTime

    attr_accessible :name

    has_and_belongs_to_many :devices, :class_name => "PushNotificationExtension::Device", :inverse_of => :channels

    has_many :messages, :class_name => "PushNotificationExtension::Message", :inverse_of => :channel

    def set_timestamps
      self.updated_at = Time.current unless self.updated_at.present?
      self.created_at = Time.current unless self.created_at.present?
      true
    end

    def publish(badge = 0, alert, sound, message_payload)
      ios_notifications     = []
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
      apns_connection = Apnotic::Connection.new(cert_path: StringIO.new(AP::PushNotificationExtension::PushNotification.apns_pem))
      Rails.logger.info("Push notification devices count: #{devices.count}")
      devices.each do |device|
        Rails.logger.info "Sending message #{message_payload}, with badge number #{badge}, to device #{device.token} of type #{device.type} for channel #{name}"

        if device.ios?
          notification = Apnotic::Notification.new(device.token)
          notification.alert = alert
          notification.badge = badge
          notification.sound = sound if !sound.blank?
          ios_notifications << notification
          push = apns_connection.prepare_push(notification)
          apns_connection.push_async(push)
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
        
        apns_connection.join(timeout: 5)
        apns_connection.close

        self.messages << Message.new(alert: alert, badge: badge, message_payload: message_payload)
      else
        Rails.logger.info "Notifications will only be sent out for a production environment."
      end
    end

  end
end
