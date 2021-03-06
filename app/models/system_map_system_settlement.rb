class SystemMapSystemSettlement < ApplicationRecord
  has_many :locations, :class_name => 'SystemMapSystemPlanetaryBodyLocation', :foreign_key => 'on_settlement_id'

  belongs_to :faction_affiliation, :class_name => 'FactionAffiliation', :foreign_key => 'faction_affiliation_id'

  belongs_to :on_planet, :class_name => 'SystemMapSystemPlanetaryBody', :foreign_key => 'on_planet_id'
  belongs_to :on_moon, :class_name => 'SystemMapSystemPlanetaryBodyMoon', :foreign_key => 'on_moon_id'
  belongs_to :safety_rating, :class_name  => 'SystemMapSystemSafetyRating', :foreign_key => 'safety_rating_id'

  belongs_to :primary_image, :class_name => 'SystemMapImage', :foreign_key => 'primary_image_id'

  def primary_image_url
    if self.primary_image != nil
      self.primary_image.image_url_thumbnail
    else
      #if this is null its need to be corrected
      self.primary_image = SystemMapImage.new
      self.save
      self.primary_image.image_url_thumbnail
    end
  end

  def title_with_kind
    "#{self.title} (Settlement)"
  end

  def title_with_location
    if on_moon_id != nil
      "#{self.title} (#{on_moon.title}, #{on_moon.orbits_planet.title}, #{on_moon.orbits_planet.orbits_system.title})"
    else
      "#{self.title} (#{on_moon.orbits_planet.title}, #{on_moon.orbits_planet.orbits_system.title})"
    end
  end

  accepts_nested_attributes_for :primary_image
end
