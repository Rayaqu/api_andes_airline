class Flight < ApplicationRecord
  belongs_to :airplane
  has_many :boarding_passes
end