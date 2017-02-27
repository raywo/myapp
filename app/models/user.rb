class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :recoverable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :trackable, :validatable

  after_create :create_tenant
  after_destroy :delete_tenant

  validates :name, presence: true
  validates :subdomain, presence: true


  def create_tenant
    Apartment::Tenant.create(subdomain)
  end # create_tenant


  def delete_tenant
    Apartment::Tenant.drop(subdomain)
  end # delete_tenant
end # class
