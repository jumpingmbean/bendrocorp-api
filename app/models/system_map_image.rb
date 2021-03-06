class SystemMapImage < ApplicationRecord
  belongs_to :of_system, :class_name => 'SystemMapSystem', :foreign_key => 'of_system_id'
  belongs_to :of_planet, :class_name => 'SystemMapSystemPlanetaryBody', :foreign_key => 'of_planet_id'
  belongs_to :of_moon, :class_name => 'SystemMapSystemPlanetaryBodyMoon', :foreign_key => 'of_moon_id'
  belongs_to :of_gravity_well, :class_name => 'SystemMapSystemGravityWellType', :foreign_key => 'of_gravity_well_id'
  belongs_to :of_system_object, :class_name => 'SystemMapSystemObject', :foreign_key => 'of_system_object_id'
  belongs_to :of_location, :class_name => 'SystemMapSystemPlanetaryBodyLocation', :foreign_key => 'of_location_id'
  belongs_to :of_settlement, :class_name => 'SystemMapSystemSettlement', :foreign_key => 'of_settlement_id'

  has_attached_file :image, :styles => { :mini => "25x25#", :small => "50x50#", :thumbnail => "100x100#", :big => "200x200#", :original => "1920x1080>" },
                    #content_type: { content_type: ["image/jpg", "image/jpeg", "image/png"] },
                    #:url  => "/assets/avatars/:id/:style/:basename.:extension",
                    #:path => ":rails_root/public/assets/system-map/:id/:style/:basename.:extension",
                    :path => "/bendrocorp/#{Rails.env}/system-map/:id/:style/:basename.:extension",
                    :default_url => "/assets/imgs/missing-system-map.png"

	validates_attachment 	:image,
				:content_type => { :content_type => /\Aimage\/.*\Z/ },
				:size => { :less_than => 10.megabyte }

  def image_url_thumbnail
    self.image.url(:thumbnail)
  end

  def image_url
    self.image.url(:original)
  end

  def image_url_big
    # NOTE may need to adjust which version this returns
    self.image.url(:big)
  end
end
