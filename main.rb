require 'telegram/bot'
require_relative 'DataManager.rb'
require 'json'
require_relative 'Mex.rb'
require_relative 'Vote.rb'

fp = "train.json"
np = "NNB/neural.json"
neural = JSON.parse(File.read(np))
token = File.read("token.safe")

dataman = DataManager.load fp


def admin? id 
    admins = [702070821, 215041592]
    !admins.index(id).nil? 
end

def clean_text(txt)
    txt = txt.gsub("\n", " ")
    txt = txt.downcase
    char_a = txt.split("")
    new_a = []
    char_a.each do |c|
        if(!(c.match(/^[[:alpha:]]$/).nil?) || c == " " )
            new_a << c
        end
    end

    txt = new_a.join 



    return txt
    
end


def find t, w
    t.each.with_index do |e, i|
        if(e["word"] == w)
            return i
        end
    end
    return nil
end

def score(text, pxc, pc, px)
    syms = ["neg", "net", "pos"]
    res = {"neg" => 1, "net" => 1, "pos" => 1}
    final_res = nil
    syms.each do |s|
        text.split(" ").each do |word|
            i = find(pxc, word)
            unless(i.nil?)
                
                res[s] *= pxc[i][s] if pxc[i][s] > 0
            end
        end
        res[s] *= pc[s]            
    end
    tot = res["neg"] + res["net"] + res["pos"]
    final_res = {"neg" => res["neg"] / tot, "net" => res["net"] / tot, "pos" => res["pos"] / tot}
end

def evaluate(scr)
    res = (10 * scr["pos"]) + (5.5 * scr["net"]) + scr["neg"]
    return res
end

def approx(n)
    if(n - n.floor >= 0.5)
        return n.ceil
    end
    return n.floor

end



Telegram::Bot::Client.run(token) do |bot|
    bot.listen do |message|
        if message.text.nil? 
            next
        end
        if message.text =~ /^\/start/ 
            bot.api.send_message(chat_id: message.chat.id, text: "So tornato pe finì quello che ho iniziato.\nOra aiutami a ricostruire il linguaggio.")
        elsif (message.text.match(/^\/vote\s+\d{1,4}/) != nil)

            mtc = message.text.match(/^\/vote\s+\d{1,4}/)
            vote = mtc[0].split(' ')[1].to_f
            msg = message.reply_to_message
            unless(msg.nil?)
                next if(msg.from.nil?)            
                if(msg.from.id != message.from.id)

                    if(vote >= 1 && vote <= 5)
                        mex = dataman.find_mex msg.message_id
                        unless mex.nil?
                            vote_i = mex.find_vote_index message.from.id
                            unless(vote_i.nil?)
                                mex.votes[vote_i] = Vote.new(message.from.id, vote, message.from.username)
                                bot.api.send_message(chat_id: message.chat.id, text: "Non credevo fossi un tipo da 'Cambiare idea è possibile'.")
                            else 
                                mex << Vote.new(message.from.id, vote, message.from.username)
                            end
                            mex.text = msg.text
                            dataman.save_mex mex
                        else
                            mex = Mex.new(msg.text, msg.message_id, [])
                            mex << Vote.new(message.from.id, vote, message.from.username)
                            dataman.save_mex mex
                            bot.api.send_message(chat_id: message.chat.id, text: "Grazie per il tuo sforzo.\nFarò tesoro di questo parere.")  
                        end
                        dataman.save fp
                        #save_json data
                    else 
                        bot.api.send_message(chat_id: message.chat.id, text: "Non mi devi prende per il culo che io ti taglio la gola.")
                    end
                else 
                    bot.api.send_message(chat_id: message.chat.id, text: "Facile succhiasselo da soli, ve'?")
                end
            end       
        elsif (message.text.match(/^\/status/) != nil)
            msg = message.reply_to_message
            unless(msg.nil?)
                mex = dataman.find_mex msg.message_id
                sub_text = ""
                unless(mex.nil?)
                    vts = mex.votes
                    tot = 0
                    vts.each do |v|
                        sub_text += "#{v.name}: #{v.vote}\n"
                        tot += v.vote
                    end
                    sub_text += "Media: #{tot/vts.count}"
                else
                    sub_text = "Ma non c'è niente da sapere"
                end
                bot.api.send_message(chat_id: message.chat.id, text: "Apprezzo il tuo dubbio.\n#{sub_text}", reply_to_message_id: message.message_id)
            end
        elsif(message.text.match(/^\/stats/) && admin?(message.from.id))
            sts = dataman.stats
            distr_s = ""
            sts[:distr].each do |k, v|
                distr_s += "Voto #{k}: #{v}\n"
            end
            dataman.plot
            bot.api.send_message(chat_id: message.chat.id, text: "Ciao Libtard, ecco le statistiche:\nTotale voti: #{sts[:n_votes]}\nDistribuzione Voti:\n#{distr_s}Media Totale: #{sts[:m_vote]}")
            bot.api.send_document(chat_id: message.chat.id, document: Faraday::UploadIO.new('plots/plot.pdf', 'multipart/form-data'))

        elsif(message.text.match(/^\/witt/))
            msg = message.reply_to_message
            unless(msg.nil?)
                unless(msg.text.nil?)
                    safe_text = clean_text(msg.text)
                    scr = score(safe_text,  neural["pxc_table"], neural["pc_table"], neural["px_table"])
                    fin = approx(evaluate(scr))
                    bot.api.send_message(chat_id: message.chat.id, text: "Il punteggio de pazzia è:\nNeg: #{scr['neg']}\nNet: #{scr['net']}\nPos: #{scr['pos']}\nConclusione: #{fin}", reply_to_message_id: msg.message_id)
                end
            end
        end
    end
end
