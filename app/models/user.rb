class User < ActiveRecord::Base
	has_secure_password	

	validates :password, length: { minimum: 6 }
	validates :name, presence: true
	validates_uniqueness_of :name
end
