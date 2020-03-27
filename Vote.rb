require "json"
class Vote 
    @id
    @vote
    def initialize id, vote, name
        @id = id 
        @vote = vote 
        @name = name
    end
    
    def id 
        @id
    end

    def vote 
        @vote 
    end

    def name 
        @name
    end

    def to_hash
        return {"vote" => @vote, "id" => @id, "name" => @name}
    end

    def to_j
        to_hash.to_json
    end

    def self.from_json value
        Vote.new(value["id"], value["vote"], value["name"])
    end
end