require 'test_helper'

class ChannelTest < ActiveSupport::TestCase
  setup do
    ENV['AP_PUSH_NOTIFICATIONS_FCM_SERVER_KEY'] = "something"
    ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT_PASSWORD'] = "something"
    @channel = FactoryGirl.create(:channel)
    Rails.stubs(:env => stub(production?: true)).returns(true)
  end
  
  test "should publish to FCM with valid attributes" do
    AP::PushNotificationExtension::PushNotification.stubs(:config).returns(fcm_server_key: "some_key") 
    FCM.any_instance.expects(:send)
    
    @channel.publish(0, "some_alert", "default", "some_payload")
    
    ENV['AP_PUSH_NOTIFICATIONS_FCM_SERVER_KEY'] = ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT_PASSWORD'] = nil
  end
  
  test "should publish to APN with valid attributes" do
    message_payload = <<-TEXT
    {"data": "stuff"}
    TEXT

    device_ios = FactoryGirl.create(:device_ios)
    
    @channel.devices << device_ios

    APNS.expects(:send_notifications)
    @channel.publish(0, "some_alert", "default", message_payload)
  end
  
end