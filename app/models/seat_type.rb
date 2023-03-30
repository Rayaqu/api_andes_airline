class SeatType < ApplicationRecord
  has_many :seats
  has_many :boarding_passes
end