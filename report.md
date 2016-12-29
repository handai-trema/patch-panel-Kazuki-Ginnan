#課題(パッチパネルの拡張) ※10/19出題の課題

氏名:銀杏一輝  
学籍番号:33E16006  


バッチファイルとOpenFlow1.3の課題についてですが、まだ完了していません。  
完了次第提出しますので、そのときはどうかよろしくお願い致します。

##課題内容
* 1.ポートのミラーリング
* 2.パッチとポートのミラーリングの一覧

###1.ポートのミラーリング
[lib/patch_panel.rb](https://github.com/handai-trema/patch-panel-Kazuki-Ginnan/blob/develop/lib/patch_panel.rb)  
[bin/patch_panel](https://github.com/handai-trema/patch-panel-Kazuki-Ginnan/blob/develop/bin/patch_panel)  

[patch_panel.rb](https://github.com/handai-trema/patch-panel-Kazuki-Ginnan/blob/develop/lib/patch_panel.rb)に以下のようにコードを追加した。

```
  def start(_args)
    @patch = Hash.new { [] }
    @mirror = Hash.new { [] }  ←追加箇所
    logger.info 'PatchPanel started.'
  end
```
↑ミラーポートを記録するために新たなハッシュテーブル@mirrorを追加した。  

```
  def create_patch_mirror(dpid, port_a, port_b)
    add_flow_entries2 dpid, port_a, port_b
    @mirror[dpid] += [[port_a, port_b]]
  end
```
↑port_aがミラーリングしたいポートであり、port_bがミラーリング先のポートである。add_flow_entries2(後述)の関数により、port_aから送信されるパケット、port_aが受信するパケットをport_bにミラーリングするようにしている。  

```
  def add_flow_entries2(dpid, port_a, port_b)
    port_c = nil

    @patch[dpid].each do |ports|
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
```
↑まず、port_aがパッチでつながっているポートを探し、それをport_cとしている。flow_modのactionsで、port_a, port_c のパケットの出力先として、port_b(ミラーリング先ポート)を追加している。  

[bin/patch_panel](https://github.com/handai-trema/patch-panel-Kazuki-Ginnan/blob/develop/bin/patch_panel)には以下のようにコードを追加した。  
```
  desc 'Mirror a new patch'
  arg_name 'dpid port#1 port#2'
  command :mirroring do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      dpid = args[0].hex
      port1 = args[1].to_i
      port2 = args[2].to_i
      Trema.trema_process('PatchPanel', options[:socket_dir]).controller.
        create_patch_mirror(dpid, port1, port2)
    end
  end
```
↑これにより、patch_panel.rbに追加した関数create_patch_mirrorを呼び出している。また、引数は 0:dpid, 1:ミラーリングしたいポート, 2:ミラーリング先のポート である。  


###2.パッチとポートのミラーリングの一覧

[patch_panel.rb](https://github.com/handai-trema/patch-panel-Kazuki-Ginnan/blob/develop/lib/patch_panel.rb)に以下のようにコードを追加した。  

```
  def list()
    patch_list()
    mirror_list()
  end
```

```
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
```

[bin/patch_panel](https://github.com/handai-trema/patch-panel-Kazuki-Ginnan/blob/develop/bin/patch_panel)には以下のようにコードを追加した。  
```
  desc 'Patch and mirror list'
  command :list do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      Trema.trema_process('PatchPanel', options[:socket_dir]).controller.
        list()
    end
  end
```

##動作例

配布されているpatch_panel.confを用いて、動作確認を行った。

###ポートのミラーリング
```
$ ./bin/patch_panel create 0xabc 1 2
$ ./bin/patch_panel mirroring 0xabc 1 3
$ ./bin/trema send_packets --source host1 --dest host2
$ ./bin/trema send_packets --source host2 --dest host1
$ ./bin/trema show_stats host1
Packets sent:
  192.168.0.1 -> 192.168.0.2 = 1 packet
Packets received:
  192.168.0.2 -> 192.168.0.1 = 1 packet
$ ./bin/trema show_stats host2
Packets sent:
  192.168.0.2 -> 192.168.0.1 = 1 packet
Packets received:
  192.168.0.1 -> 192.168.0.2 = 1 packet
$ ./bin/trema show_stats host3
$ trema dump_flows patch_panel
NXST_FLOW reply (xid=0x4):
 cookie=0x0, duration=66.178s, table=0, n_packets=1, n_bytes=42, idle_age=53, priority=0,in_port=1 actions=output:2,output:3
 cookie=0x0, duration=66.171s, table=0, n_packets=1, n_bytes=42, idle_age=40, priority=0,in_port=2 actions=output:1,output:3
↑これにより、ポート3にポート1とポート2間でのパケットが出力されていることが確認できる。
```
上記の結果からポートのミラーリングができていることがわかる。

###パッチとポートのミラーリングの一覧

ポートのミラーリングでの動作確認の続きから以下のように動作確認を行った。

```
$ ./bin/patch_panel list

(↓別のターミナル)
<patch List>
dpid : 0xabc
patch ports :
1 -- 2
<mirror List>
dpid : 0xabc
patch ports :
1 →  3

```
上記の結果からパッチとポートのミラーリングの一覧が表示できていることが確認できた。

##謝辞
今回のレポートを作成するにあたって、コードについては[成元君](https://github.com/handai-trema/learning-switch-r-narimoto/blob/master/report13.md)レポートを、動作確認については[阿部君](https://github.com/handai-trema/learning-switch-shuya-abe/blob/develop/report3-2.md)のレポートを参考にさせていただきました。ありがとうございました。





