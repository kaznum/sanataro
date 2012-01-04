class User < ActiveRecord::Base
	acts_as_tagger
	attr_accessor :password_plain, :password_confirmation
	has_many :items
	has_many :monthly_profit_losses
	has_many :accounts
	has_many :credit_relations

	N_("User|Password plain")
	N_("User|Password confirmation")

	validate :validate_everytime
	validates_presence_of :login
	validates_presence_of :password_plain, :if => :password_required?
	validates_presence_of :email
	validates_format_of :login, :with => /^[A-Za-z0-9_-]+$/
	validates_length_of :login, :in =>3..10
	validates_format_of :password_plain, :with => /^[A-Za-z0-9_-]+$/, :if => :password_required?
	validates_length_of :password_plain, :in =>6..10, :if => :password_required?
	validates_uniqueness_of :login, :message => N_("%{fn[:attribute]} has already been used. Input another UserID.")

	validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
	validates_length_of :email, :in =>5..255

	before_save :hash_password

	def validate_everytime
		errors.add("password_plain", _("%{fn[:password_plain]} is not same.")) if self.password_required? && self.password_plain != self.password_confirmation
	end

	def password_required?
		self.password.blank? || !self.password_plain.blank?
	end

	def hash_password
		return if self.password_plain.blank?
		self.password = CommonUtil.crypt(login + self.password_plain)
	end

  def get_separated_accounts
    accounts = self.accounts.active.order("account_type, order_no")
    from  = Array.new
    to  = Array.new
    bank_accounts = Array.new
    all_accounts  = Hash.new
    all_accounts.default = _('(unknown)')
    income_ids = Array.new
    outgo_ids = Array.new
    account_ids = Array.new
    account_bgcolors = Hash.new

    tmp_accounts = Array.new

    accounts.each do |a|
      case a.account_type
      when 'outgo'
        to.push [a.name, a.id.to_s]
        outgo_ids.push a.id
      when 'income'
        from.push [a.name, a.id.to_s]
        income_ids.push a.id
      when 'account'
        tmp_accounts.push [a.name, a.id.to_s]
        from.push [a.name, a.id.to_s]
        bank_accounts.push [a.name, a.id.to_s]
        account_ids.push a.id
      end
      all_accounts[a.id] = a.name
      account_bgcolors[a.id] = a.bgcolor unless a.bgcolor.nil?
    end

    to += tmp_accounts


    return { :from_accounts => from,
      :to_accounts => to,
      :bank_accounts => bank_accounts,
      :all_accounts => all_accounts,
      :income_ids => income_ids,
      :outgo_ids => outgo_ids,
      :account_ids => account_ids,
      :account_bgcolors => account_bgcolors
    }

  end
  
end
