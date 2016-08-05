namespace :rabbit do
 
  def get_queues
    `#{@base_command} list queues | awk '{print$4}' | grep -vw '|' | grep -vw 'name' | awk 'NF'`
  end
 
  def get_queues_with_count
    `#{@base_command} list queues | awk '{print$19, $4}' | grep -vw '|' | grep -vw 'name' | awk 'NF'`
  end
 
  def get_exchanges
    `#{@base_command} list exchanges | grep -vw 'amq' | awk '{print$4}' | grep -vw '|' | grep -vw 'name' | awk 'NF'`
  end
 
  def load_config
    @config ||= HashWithIndifferentAccess.new(YAML::load_file File.join(Rails.root, "config/rabbitmq.yml"))[Rails.env]
  end
 
  def configure_command
    load_config
    @base_command ||= "/usr/sbin/rabbitmqadmin -H #{@config[:host]} -P #{@config[:port]} -u #{@config[:user]} -p #{@config[:password]}"
  end
 
  def delete_queues(force)
    configure_command
    queue_list = get_queues_with_count
 
    unless queue_list.nil?
      queues = queue_list.split("\n")
      puts queues
      queues.each do |queue|
        q_detail = queue.split(" ")
        if q_detail[0] == "0" or force
          delete(@base_command, 'queue', q_detail[1])
        else
          puts `echo "$(tput setaf 3)$(tput bold)Warning! #{q_detail[1]} contains messages and must be cleared manually$(tput sgr0)"`
        end
      end
    end
  end
 
  desc "Prepares the current system to be able to run the rabbit rake tasks.  !!! It must be run before you can execute any of the other tasks !!!"
  task :setup => :environment do
    puts `sudo curl -L -o /usr/sbin/rabbitmqadmin http://hg.rabbitmq.com/rabbitmq-management/raw-file/rabbitmq_v3_0_4/bin/rabbitmqadmin`
    puts `sudo chmod 755 /usr/sbin/rabbitmqadmin`
  end
 
  namespace :delete do
 
    desc "Deletes all Exchanges within RabbitMQ"
    task :exchanges => :environment do
      configure_command
      exchange_list = get_exchanges
 
      unless exchange_list.nil?
        exchanges = exchange_list.split("\n")
 
        exchanges.each do |exchange|
          delete(@base_command, 'exchange', exchange)
        end
      end
    end
 
    desc "Deletes all empty Queues within RabbitMQ"
    task :queues => :environment do
      delete_queues(false)
    end
 
    desc "Deletes all Queues (and messages) within RabbitMQ"
    task :queues_by_force => :environment do
      delete_queues(true)
    end
 
    desc "Deletes all Exchanges and empty Queues within RabbitMQ"
    task :all => [:exchanges, :queues]
 
    def delete(command, type, name)
      puts `#{command} delete #{type} name=#{name}`
    end
 
  end
 
  desc "Configures Exchanges, Queues and Bindings based on config/rabbitmq.yml"
  task :configure => :environment do
    configure_command
 
    exchange_list = get_exchanges
    unless exchange_list.nil?
      exchanges = exchange_list.split("\n")
 
      exchanges.each do |e|
        puts `echo "$(tput setaf 1)$(tput bold)Exchange #{e} exists, please run rabbit:delete:exchanges to remove$(tput sgr0)"`
      end
    end
 
    queue_list = get_queues
    unless queue_list.nil?
      queues = queue_list.split("\n")
      queues.each do |q|
        puts `echo "$(tput setaf 1)$(tput bold)Queue #{q} exists, please run rabbit:delete:queues to remove, if messages exist you must clear the queue$(tput sgr0)"`
      end
    end
 
    config = HashWithIndifferentAccess.new(YAML::load_file File.join(Rails.root, "config/rabbitmq.yml"))[Rails.env]
 
    exchange_defaults = {:vhost => 'caishuo', :durable => true, :auto_delete => false, :arguments => {}}
    exchanges = []
    config[:exchanges].each do |e|
      raise ArgumentError, "Invalid entry #{e}." if e[:name].nil? || e[:name].blank? || e[:type].nil? || e[:type].blank? || e[:internal].nil?
      entry = e.merge(exchange_defaults)
      entry[:arguments] = {'alternate-exchange' => entry.delete('alternate_exchange')} if entry.has_key?('alternate_exchange')
      exchanges << entry
    end
 
    queue_defaults = {:vhost => "caishuo", :durable => true, :auto_delete => false, :arguments => {}}
    queues = []
    config[:queues].each do |q|
      raise ArgumentError, "Invalid entry #{q}." if q[:name].nil? || q[:name].blank?
      entry = q.merge(queue_defaults)
 
      entry[:arguments]['x-dead-letter-exchange'] = entry.delete('dead_letter_exchange') if entry.has_key?('dead_letter_exchange')
      entry[:arguments]['x-dead-letter-routing-key'] = entry.delete('dead_letter_routing_key') if entry.has_key?('dead_letter_routing_key')
      entry[:arguments]['x-message-ttl'] = entry.delete('message_expiration') if entry.has_key?('message_expiration')
      queues << entry
    end
 
 
    binding_defaults = {:vhost => "caishuo", :arguments => {}}
    bindings = []
    config[:bindings].each do |b|
      raise ArgumentError, "Invalid entry #{b}." if b[:source].nil? || b[:source].blank? || b[:destination].nil? || b[:destination].blank? || b[:destination_type].nil? || b[:destination_type].blank?
      entry = b.merge(binding_defaults)
      bindings << entry
    end
 
    #pull rabbit configuration to json
    puts `#{@base_command} export rabbit.config`
 
    current_config = JSON.parse(File.open('rabbit.config', 'rb') { |f| f.read })
    current_config["exchanges"] += exchanges
    current_config["queues"] += queues
    current_config["bindings"] += bindings
 
    #save changes to configuration and load into rabbit
    File.open('rabbit.config', 'w') { |f| JSON.dump(current_config, f) }
    puts `#{@base_command} import rabbit.config`
    puts `rm -f rabbit.config`
  end
end