# Software patch-panel.
class PatchPanel < Trema::Controller
  def start(_args)
    @patch = Hash.new { [] }
    @mirror = Hash.new { [] }
    logger.info 'PatchPanel started.'
  end

  def switch_ready(dpid)
    @patch[dpid].each do |port_a, port_b|
      delete_flow_entries dpid, port_a, port_b
      add_flow_entries dpid, port_a, port_b
    end

    @mirror[dpid].each do |port_a, port_b|
    delete_flow_entries dpid, port_a, port_b
     add_flow_entries dpid, port_a, port_b
    end
  end

  def create_patch(dpid, port_a, port_b)
    add_flow_entries dpid, port_a, port_b
    @patch[dpid] += [[port_a, port_b].sort]
  end

#add
  def create_patch_mirror(dpid, port_a, port_b)
    add_flow_entries2 dpid, port_a, port_b
    @mirror[dpid] += [[port_a, port_b]]
  end
#add end

  def delete_patch(dpid, port_a, port_b)
    delete_flow_entries dpid, port_a, port_b
    @patch[dpid] -= [port_a, port_b].sort
  end

  def list()
    patch_list()
    mirror_list()
  end

  private

  def add_flow_entries(dpid, port_a, port_b)
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_a),
                      actions: SendOutPort.new(port_b))
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_b),
                      actions: SendOutPort.new(port_a))
  end

#add
  def add_flow_entries2(dpid, port_a, port_b)
    port_c = nil

    @patch[dpid].each do |ports|
#puts ports[0]
#puts ports[1]
    port_c = ports[0] if ports[1] == port_a
    port_c = ports[1] if ports[0] == port_a
    end
  

return if port_c.nil?
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_a))
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_b))

    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_a),
                      actions: [SendOutPort.new(port_c), SendOutPort.new(port_b)])
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_c),
                      actions: [SendOutPort.new(port_a), SendOutPort.new(port_b)])
puts port_c
  end
#add end



  def delete_flow_entries(dpid, port_a, port_b)
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_a))
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_b))
  end


  def patch_list()
puts "<patch List>"
     @patch.each do |dpid|
      puts "dpid : 0x#{dpid[0].to_s(16)}"
      #puts "\n"
      dpid[1].each do |ports|
        puts "patch ports :"
        puts "#{ports[0]} -- #{ports[1]}"
        #puts "\n"
      end
     end  
  end

  def mirror_list()
puts "<mirror List>"
     @mirror.each do |dpid|
      puts "dpid : 0x#{dpid[0].to_s(16)}"
      #puts "\n"
      dpid[1].each do |ports|
        puts "mirorr ports :"
        puts "#{ports[0]} →  #{ports[1]}"
        #puts "\n"
      end
     end  
  end
end



