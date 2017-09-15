class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  before_validation :twitter,
                    :sanitize_inputs

  validates :twitter,
    length: { maximum: 15 },
    format: {
      with: /\A[a-zA-Z0-9_]+\z/,
      message: "accepts only alphanumeric and underscore characters"
    },
    allow_blank: true
  validates :linked_in,
    length: { in: 5..30 },
    format: {
      with: /\A[a-zA-Z0-9-]+\z/,
      message: "accepts only alphanumeric characters"
    },
    allow_blank: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  has_many :affiliations, dependent: :destroy
  has_many :groups, through: :affiliations
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :invitations
  belongs_to :cohort

  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner

  # paperclip configuration
  has_attached_file :image, default_url: "images/:style/missing.png", styles: {
    thumb: '100x100>',
    square: '200x200#',
    medium: '300x300>'
  }
  # Validate the attached image is image/jpg, image/png, etc
  validates_attachment :image, content_type: { content_type: ["image/jpeg",
                                                              "image/gif",
                                                              "image/png"] }


  def full_name
    "#{first_name} #{last_name}"
  end

  def list_roles
    roles.map { |role| role.name }.join(', ')
  end

  def list_groups
    groups.map {|group| group.name }.join(', ')
  end

  def has_role?(role)
    roles.where(name: "#{role}").exists?
  end

  def self.search_by_name(term)
    User.where(
      "upper(first_name) LIKE ? OR
      upper(last_name) LIKE ?",
      "%#{term.upcase}%",
      "%#{term.upcase}%").
      order(:id)
  end

  def sanitize_inputs
    # Remove any "@" symbols from the begining of the string.
    twitter.sub!(/\A@+/,"") if twitter
  end

  # def set_role
  #   role = Role.find_or_create_by(name: 'enrolled')
  #   roles << role
  # end

  def change_role(new_role_name)
    new_role = Role.find_by(name: new_role_name)

    if new_role.name.in?(['graduated', 'exited', 'removed'])
      student = roles.find_by(name: 'active student')
      roles.delete(student) if student
      roles << new_role
    end

    if new_role.name == 'active student'
      applicant = roles.find_by(name: 'applicant')
      roles.delete(applicant) if applicant
      roles << new_role
    end
  end

  def cohort_name
    if cohort
      cohort.name
    else
      "n/a"
    end
  end

  def self.search_all(query)
    terms = query.upcase.split
    users = User.none
    terms.each do |term|
      users += search_cohorts(term)
      users += search_roles(term)
      users += search_groups(term)
      users += search_users(term)
    end
    users.flatten
  end

  def self.search_cohorts(query)
    cohorts = Cohort.where(
      "upper(name) LIKE ?",
      "%#{query.upcase}%"
      )
    users = cohorts.map do |cohort|
      cohort.users
    end
  end

  def self.search_roles(query)
    roles = Role.where(
      "upper(name) LIKE ?",
      "%#{query.upcase}%"
      )

    users = roles.map do |role|
      role.users
    end

  end

  def self.search_groups(query)
    groups = Group.where(
      "upper(name) LIKE ?",
      "%#{query.upcase}%"
      )
    users = groups.map do |group|
      group.users
    end
  end

  def self.search_users(query)
    # query.split.map do |term|
       User.where(
        "upper(first_name) LIKE ? OR
        upper(last_name) LIKE ?",
        "%#{query.upcase}%",
        "%#{query.upcase}%"
      )
  end


end
