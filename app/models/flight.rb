class Flight < ApplicationRecord
  belongs_to :airplane
  has_many :boarding_passes, dependent: :destroy
  has_many :passengers, through: :boarding_passes
  has_many :seats, through: :airplane
end