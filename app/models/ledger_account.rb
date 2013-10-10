class LedgerAccount < ActiveRecord::Base

  attr_accessible :name, :code, :code_name, :master_ledger_account_id, :master_ledger_account, :contable

  belongs_to :contable, polymorphic: true

  has_many :child_ledger_accounts, :class_name => "LedgerAccount", :foreign_key => "master_ledger_account_id", :order => 'order_column'
  belongs_to :master_ledger_account, :class_name => "LedgerAccount"  

  default_scope order('order_column ASC')
  
  validates :master_ledger_account_id, :presence => true

  before_save :set_code_name
  before_save :set_code

  after_create :set_order_column

  def self.account(value)
    where(:code_name => value.to_s.snp_underscore).first
  end

  def set_code
    unless self.master_ledger_account_id == 0
      unless self.order_column.nil?
        self.code = "#{self.master_ledger_account.code}.#{self.order_column}"
      end
    end
  end

  def re_code(parent_code)
    self.code = "#{parent_code}#{parent_code.blank? ? '' : '.'}#{order_column}"
    save
    child_ledger_accounts.each do |child|
      child.re_code(code)
    end
  end  


  def set_code_name
    if (read_attribute(:code_name)).blank?
      name_value = read_attribute(:name)
      write_attribute :code_name, name_value.snp_underscore
    end
  end

  def set_order_column
    #Solo agrega orden si la cuenta no es tope del arbol
    unless self.master_ledger_account_id == 0
      max = self.master_ledger_account.child_ledger_accounts.maximum(:order_column)
    else
      max = LedgerAccount.where(:master_ledger_account_id => 0).maximum(:order_column)
    end

    if max.nil?
      self.order_column = 1
    else
      self.order_column = max + 1
    end

    self.save
  end


end


