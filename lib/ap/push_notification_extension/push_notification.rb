require 'openssl'
module AP
  module PushNotificationExtension
    module PushNotification
      @@config = Hash.new
      def self.config_account(config={})
        config = HashWithIndifferentAccess.new(config)

        @@config[:fcm_server_key] = ENV['AP_PUSH_NOTIFICATIONS_FCM_SERVER_KEY'].blank? ? config[:fcm_server_key] : ENV['AP_PUSH_NOTIFICATIONS_FCM_SERVER_KEY']

        @@config[:apple_cert] = ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT'].blank? ? config[:apple_cert] : ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT']
        @@config[:apple_cert_password] = ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT_PASSWORD'].blank? ? config[:apple_cert_password] :  ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT_PASSWORD']

        cert_valid = false
        if @@config[:apple_cert] && File.file?("#{Rails.root}#{@@config[:apple_cert]}")
          keystore = OpenSSL::PKCS12.new(File.binread("#{Rails.root}#{@@config[:apple_cert]}"), @@config[:apple_cert_password])
          @@config[:apns_cert_pem_string] = keystore.certificate.to_pem
          cert_valid = true
        end
        raise "No push services configured!" unless cert_valid || @@config[:fcm_server_key]
      end

      def self.config
        @@config
      end

      def self.json_config
        @@json ||= ActiveSupport::JSON.decode(File.read("#{File.dirname(__FILE__)}/../../../manifest.json"))
      end

      def execute_push_notification(object, options = {})
        options = HashWithIndifferentAccess.new(options)
        channel = ::PushNotificationExtension::Channel.where(name: options[:channel]).first || ::PushNotificationExtension::Channel.create(name: options[:channel])
        channel.publish(options[:badge], options[:alert], options[:sound], options[:message_payload])
      end
    end
  end
end
