class User < ActiveRecord::Base
  attr_accessible :name, :password
  validates :name, :presence => true, :length => { :in => 3..10 }, :uniqueness => true
  validates :password, :presence => true
end
