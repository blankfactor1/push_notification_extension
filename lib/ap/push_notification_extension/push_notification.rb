module AP
  module PushNotificationExtension
    module PushNotification
      @@config = Hash.new
      def self.config_account(config={})
        config = HashWithIndifferentAccess.new(config)

        @@config[:gcm_api_key_password] = ENV['AP_PUSH_NOTIFICATIONS_GCM_PASSWORD'].blank? ? config[:gcm_api_key_password] : ENV['AP_PUSH_NOTIFICATIONS_GCM_PASSWORD']
        @@config[:gcm_keystore] = ENV['AP_PUSH_NOTIFICATIONS_GCM_KEYSTORE'].blank? ? config[:gcm_keystore] : ENV['AP_PUSH_NOTIFICATIONS_GCM_KEYSTORE']
        @@config[:gcm_token_path] = ENV['AP_PUSH_NOTIFICATIONS_GCM_TOKEN'].blank? ? config[:gcm_token_path] : ENV['AP_PUSH_NOTIFICATIONS_GCM_TOKEN']

        keystore = OpenSSL::PKCS12.new(File.binread("#{Rails.root}#{@@config[:gcm_keystore]}"), @@config[:gcm_api_key_password])
        key = keystore.key
        safe_token = File.binread("#{Rails.root}#{@@config[:gcm_token_path]}")

        @@config[:gcm_api_key] = key.private_decrypt(safe_token)

        Rails.logger.info "GCM KEY: #{@@config[:gcm_api_key]}"

        @@config[:apple_cert] = ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT'].blank? ? config[:apple_cert] : ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT']
        @@config[:apple_cert_password] = ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT_PASSWORD'].blank? ? config[:apple_cert_password] :  ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT_PASSWORD']

        cert_valid = false
        if @@config[:apple_cert] && File.file?("#{Rails.root}#{::AP::PushNotificationExtension::PushNotification.config[:apple_cert]}")

          APNS.keystore  = "#{Rails.root}#{::AP::PushNotificationExtension::PushNotification.config[:apple_cert]}"
          APNS.pass = ::AP::PushNotificationExtension::PushNotification.config[:apple_cert_password] unless ::AP::PushNotificationExtension::PushNotification.config[:apple_cert_password].blank?

          #pem_file = File.open("#{Rails.root}/#{::AP::PushNotificationExtension::PushNotification.config[:apple_cert]}")
          #pem_file_contents = pem_file.read
          #unless pem_file_contents.match(/Apple Development IOS Push Services/)
            # This is for production apps/certs only.
            APNS.host = 'gateway.push.apple.com'
          #end
          #pem_file.close
          APNS.port = 2195
          cert_valid = true
        end
        raise "No push services configured!" unless cert_valid || @@config[:gcm_api_key]
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
