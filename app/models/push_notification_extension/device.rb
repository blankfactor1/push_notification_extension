module PushNotificationExtension
  class Device
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
    
    before_create :set_timestamps

    IOS = "ios"
    ANDROID = "android"
    TYPES = [IOS, ANDROID]

    # Unique device token.
    field :token, type: String
    # Device type, currently only iOS or Android.
    field :type, type: String
    # add timestamp fields manually to avoid undefined method `to_datetime' for false:FalseClass
    field :updated_at, type: DateTime
    field :created_at, type: DateTime

    validates :token, presence: true, uniqueness: { scope: :type }, format: { without: /null/ }
    validates :type, presence: true, inclusion: { in: TYPES }

    before_validation :scrub

    attr_accessible :token, :type

    has_and_belongs_to_many :channels, :class_name => "PushNotificationExtension::Channel"

    def set_timestamps
      self.updated_at = Time.current unless self.updated_at.present?
      self.created_at = Time.current unless self.created_at.present?
      true
    end

    def self.scrub_token(token_value)
      token_value.gsub(/\s|<|>/,'')
    end

    def ios?
      type.eql? IOS
    end

    def android?
      type.eql? ANDROID
    end

    def scrub
      self.token = PushNotificationExtension::Device.scrub_token(token)
    end

  end
end
