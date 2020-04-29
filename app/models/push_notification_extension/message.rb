module PushNotificationExtension
  class Message
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
    
    before_create :set_timestamps
    
    paginates_per 10
    
    attr_accessible :alert, :badge, :message_payload
    
    field :alert, type: String
    field :badge, type: String
    field :message_payload, type: String
    # add timestamp fields manually to avoid undefined method `to_datetime' for false:FalseClass
    field :updated_at, type: DateTime
    field :created_at, type: DateTime
    
    belongs_to :channel, class_name: "PushNotificationExtension::Channel", inverse_of: :channel

    def set_timestamps
      self.updated_at = Time.current unless self.updated_at.present?
      self.created_at = Time.current unless self.created_at.present?
      true
    end
    
  end
end
