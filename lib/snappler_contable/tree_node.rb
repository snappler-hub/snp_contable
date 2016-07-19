module SnapplerContable
  class TreeNode

    include Enumerable

    attr_accessor :object, :children, :root

    # def initialize(account, root=false)
    #   if root
    #     @object = 'ROOT'
    #   else
    #     @object = account
    #   end
    #   @childrens = []
    #   @root = root
    # end

    def initialize(account, root=false)
      @root     = root
      @object   = root ? 'ROOT' : account
      @children = []
    end

    #def add_child_ledger_accounts(accounts)
    #  accounts.each do |account|
    #    node = TreeNode.new(account)
    #    children << node
    #    node.add_child_ledger_accounts(account.child_ledger_accounts)
    #  end
    #end

    # Revisar
    def add_accounts(accounts)
      self.children = accounts.map do |account|
        node = TreeNode.new(account)
        node.add_accounts(account.child_ledger_accounts)
        node
      end
    end
    alias_method :add_child_ledger_accounts, :add_accounts

    def name
      root ? 'ROOT' : "#{object.code} : #{object.name} (#{object.id})"
    end

    # def to_s(indent=0)
    #   res = (' ' * indent) + "#{name}\n"
    #   res = res + @children.map{ |child| " " + child.to_s(indent + 4)}.join("\n")
    #   res.gsub("\n\n", "\n")
    # end

    def to_s(indentation=0)
      res = "#{' ' * indentation}#{name}\n"
      res = res + @children.map{ |child| " " + child.to_s(indentation + 4)}.join("\n")
      res.gsub("\n\n", "\n")
    end

    def each(&block)
      unless root
        block.call object
      end
      children.each do |child|
        child.each(&block)
      end
      self
    end

  end
end