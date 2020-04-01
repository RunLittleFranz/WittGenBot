require "json"
require "squid"
class DataManager

    @source 
    def initialize data
        @source = data
    end


    def find_mex msg_id
        i = find_mex_index msg_id
        unless i.nil?
            return Mex.from_json @source[i]
        end
        return nil
    end

    def find_mex_index msg_id
        j = nil
        @source.each.with_index do |mex, i|
            #mx = Mex.from_json mex
            if(mex["id"] == msg_id)
                j = i
                break
            end
        end
        return j
    end

    def save_mex mex 
        i = find_mex_index mex.id
        unless i.nil?
            @source[i] = mex.to_hash
        else 
            @source << mex.to_hash
        end
    end

    def source 
        @source
    end

    def self.load filepath
        cont = File.read(filepath)
        DataManager.new(JSON.parse(cont))
    end

    def save filepath
        #puts @source.inspect
        File.write(filepath, @source.to_json)
    end

    def stats
        h_stats = {n_votes: 0, 
                   distr: {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5"=> 0},
                   m_vote: 0
                }
        
        @source.each do |mex|
            mx = Mex.from_json mex
            next if mx.text.nil?
            h_stats[:n_votes] += 1
            scl_v = 0
            mx.votes.each do |v|
                scl_v += v.vote
            end
            m = scale(approx(scl_v / mx.votes.count))
            h_stats[:distr][m.to_s] += 1
        end

        tot_v = 0
        tot_n = 0
        h_stats[:distr].each do |k, v|
            tot_v += k.to_f * v.to_f
            tot_n += v
        end
        h_stats[:m_vote] = approx(tot_v / tot_n.to_f)
        
        return h_stats
    end

    def plot 
        st = stats
        fp = "plots/plot.pdf"
        Prawn::Document.generate(fp) do

            chart views: st[:distr]
        end
    end

    private 

    def scale(n)
        s = n / 2
        r = n % 2
        return s + r
    end

    def approx(n)
        if(n - n.floor >= 0.5)
            return n.ceil
        end
        return n.floor

    end


end