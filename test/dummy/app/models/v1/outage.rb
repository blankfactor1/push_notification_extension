class V1::Outage
  include Mongoid::Document
  include AP::PushNotificationExtension::PushNotification
  
  before_create :set_timestamps

  # Field definitions
  
  field :"title", type: String
  # add timestamp fields manually to avoid undefined method `to_datetime' for false:FalseClass
  field :updated_at, type: DateTime
  field :created_at, type: DateTime

  def set_timestamps
    self.updated_at = Time.current unless self.updated_at.present?
    self.created_at = Time.current unless self.created_at.present?
    true
  end
 
end
