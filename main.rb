require 'telegram/bot'
require 'json'
require_relative 'Mex.rb'
require_relative 'Vote.rb'

token = File.read(token.key)

def load_json
    cont = File.read("train.json")
    return JSON.parse(cont)
end

def save_json data
    cont = File.read("train.json")
    File.write("train_bk.json", cont)
    File.write("train.json", data.to_json)
end



data = load_json
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
                if(msg.from.id != message.from.id)

                    if(vote >= 1 && vote <= 10)
                        found = false
                        allowed = true
                        j = 0
                        data.each.with_index do |mex, i|
                            mx = Mex.from_json mex
                            if(mx.id == msg.message_id)
                                j = i
                                found = true
                                break
                            end
                        end
                        if found 
                            mx = Mex.from_json data[j]
                            mx.votes.each.with_index do |v, i|
                                if(v.id == msg.from.id)
                                    allowed = false
                                    mx.votes[i] = Vote.new(msg.from.id, vote, message.from.username)
                                    data[j] = mx.to_hash
                                    bot.api.send_message(chat_id: message.chat.id, text: "Non credevo fossi un tipo da 'Cambiare idea è possibile'.")
                                end
                            end
                            if allowed
                                mx = Mex.from_json data[j]
                                mx << Vote.new(msg.from.id, vote, message.from.username)
                                data[j] = mx.to_hash
                            end
                        else
                            mx = Mex.new(msg.text, msg.message_id, [])
                            mx << Vote.new(msg.from.id, vote, message.from.username)
                            data << mx.to_hash
                        end
                        bot.api.send_message(chat_id: message.chat.id, text: "Grazie per il tuo sforzo.\nFarò tesoro di questo parere.") if allowed
                        puts data.inspect
                        save_json data
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
                found = false
                j = 0
                data.each.with_index do |mex, i|
                    mx = Mex.from_json mex
                    if(mx.id == msg.message_id)
                        j = i
                        found = true
                        break
                    end
                end
                sub_text = ""
                if(found)
                    vts = Mex.from_json(data[j]).votes
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
        end
    end
end