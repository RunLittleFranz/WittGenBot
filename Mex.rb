require "json"
#test
class Mex 
    @text
    @id
    @votes
    def initialize text, id, votes
        @text = text 
        @id = id
        @votes = votes
    end

    def text 
        @text 
    end

    def text=(v)
        @text = v
    end

    def id 
        @id 
    end

    def votes 
        @votes 
    end

    def votes=(value)
        @votes = value
    end

    def <<(value)
        @votes << value
    end


    def find_vote_index vote_id #vote_id = message.from.id
        @votes.each.with_index do |v, i|
            if(v.id == vote_id)
                return i
            end
        end
        return nil
    end

    def to_hash
        return {"message" => @text, "id" => @id, "votes" => @votes.map { |v| v.to_hash}}
    end

    def self.from_json value
        return Mex.new(value["message"], value["id"], value["votes"].map{ |v| Vote.from_json(v)})
    end

    
end
