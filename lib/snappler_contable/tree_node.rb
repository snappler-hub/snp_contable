module SnapplerContable
  class TreeNode

    include Enumerable

    attr_accessor :object, :childrens, :root

    def initialize(account, root=false)
      if root
        @object = 'ROOT'
      else
        @object = account
      end
      @childrens = []
      @root = root
    end

    def add_child_ledger_accounts(accounts)
      accounts.each do |account|
        node = TreeNode.new(account)
        childrens << node
        node.add_child_ledger_accounts(account.child_ledger_accounts)
      end
    end

    def name
      root ? 'ROOT' : "#{object.code} : #{object.name}"
    end

    def to_s(indent=0)
      res = (' ' * indent) + "#{name}\n"
      res = res + @childrens.map{ |child| " " + child.to_s(indent + 4)}.join("\n")
      res.gsub("\n\n", "\n")
    end

    def each(&block)
      unless root
        block.call object
      end
      childrens.each do |child|
        child.each(&block)
      end
      self
    end  

  end
end