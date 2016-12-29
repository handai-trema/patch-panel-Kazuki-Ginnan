#OpenFlow 1.3版 マルチプルテーブルを読む ※10/19出題の課題
氏名:銀杏一輝  
学籍番号:33E16006  

提出遅くなり大変申し訳ありません。お手数をおかけしますが、確認していただければ幸いです。

##課題内容
OpenFlow1.3 版スイッチの動作を説明しよう。

スイッチ動作の各ステップについて、trema dump_flows の出力 (マルチプルテーブルの内容) を混じえながら動作を説明すること。

##結果
trema.confを用いて、OpenFlow1.3を動かしてみた。

```
vswitch('lsw') {
  datapath_id 0xabc
}

vhost ('host1') {
  ip '192.168.0.1'
}

vhost ('host2') {
  ip '192.168.0.2'
}

link 'lsw', 'host1'
link 'lsw', 'host2'
```
まず、learning_switch13.rbを起動させた状態で、trema dump_flows lsw コマンドを入力して初期状態のフローテーブルを確認した。

```
cookie=0x0, duration=188.888s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=01:00:00:00:00:00/ff:00:00:00:00:00 actions=drop
cookie=0x0, duration=188.848s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=33:33:00:00:00:00/ff:ff:00:00:00:00 actions=drop
cookie=0x0, duration=188.848s, table=0, n_packets=0, n_bytes=0, priority=1 actions=goto_table:1
cookie=0x0, duration=188.848s, table=1, n_packets=0, n_bytes=0, priority=3,dl_dst=ff:ff:ff:ff:ff:ff actions=FLOOD
cookie=0x0, duration=188.848s, table=1, n_packets=0, n_bytes=0, priority=1 actions=CONTROLLER:65535

```
table=0はフィルタリングテーブルを表しており、このテーブルでは転送しないパケットをドロップすることを最優先に行っている。
table=1は転送テーブルを表しており、priroty=3では宛先MACアドレスがわからないので、フラッディングするようにしている。ff:ff:ff:ff:ff:ffはブロードキャストアドレスである。
priority=1はコントローラになっており、コントローラにはPaketIn()のみを送信すればよいので、優先度が低いことがわかる。  

次に、host1からhost2へパケットを送信してみた後にフローテーブルを確認した。


```
cookie=0x0, duration=327.823s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=01:00:00:00:00:00/ff:00:00:00:00:00 actions=drop
cookie=0x0, duration=327.783s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=33:33:00:00:00:00/ff:ff:00:00:00:00 actions=drop
cookie=0x0, duration=327.783s, table=0, n_packets=1, n_bytes=42, priority=1 actions=goto_table:1
cookie=0x0, duration=327.783s, table=1, n_packets=0, n_bytes=0, priority=3,dl_dst=ff:ff:ff:ff:ff:ff actions=FLOOD
cookie=0x0, duration=327.783s, table=1, n_packets=1, n_bytes=42, priority=1 actions=CONTROLLER:65535
```
PacketIn()が起こったため、フィルタリングテーブルでprirotiy=1のように、転送テーブルのパケットが送られており、転送テーブルではコントローラにパケットが送られていることがわかる。  

次に、host2からhost1へパケットを送信してみた後にフローテーブルを確認した。
```
cookie=0x0, duration=498.556s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=01:00:00:00:00:00/ff:00:00:00:00:00 actions=drop
cookie=0x0, duration=498.516s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=33:33:00:00:00:00/ff:ff:00:00:00:00 actions=drop
cookie=0x0, duration=498.516s, table=0, n_packets=2, n_bytes=84, priority=1 actions=goto_table:1
cookie=0x0, duration=498.516s, table=1, n_packets=0, n_bytes=0, priority=3,dl_dst=ff:ff:ff:ff:ff:ff actions=FLOOD
cookie=0x0, duration=5.259s, table=1, n_packets=0, n_bytes=0, idle_timeout=180, priority=2,in_port=2,dl_src=a3:a0:44:7b:d8:7e,dl_dst=93:22:0c:90:c1:a0 actions=output:1
cookie=0x0, duration=498.516s, table=1, n_packets=2, n_bytes=84, priority=1 actions=CONTROLLER:65535
```
ここで、host2からのPaketIn()が起こるのと同時に、flow_modによって、host2からhost1へのフローエントリが転送テーブルに追加されていることがわかる。これにより、フローにしたがっての送信はPacketIn()が必要なくなるので、コントローラへの送信より、priorityが高いことがわかる。  

次に、再度host1からhost2へパケットを送信してみた後にフローテーブルを確認した。
```
cookie=0x0, duration=610.834s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=01:00:00:00:00:00/ff:00:00:00:00:00 actions=drop
cookie=0x0, duration=610.794s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=33:33:00:00:00:00/ff:ff:00:00:00:00 actions=drop
cookie=0x0, duration=610.794s, table=0, n_packets=3, n_bytes=126, priority=1 actions=goto_table:1
cookie=0x0, duration=610.794s, table=1, n_packets=0, n_bytes=0, priority=3,dl_dst=ff:ff:ff:ff:ff:ff actions=FLOOD
cookie=0x0, duration=117.537s, table=1, n_packets=0, n_bytes=0, idle_timeout=180, priority=2,in_port=2,dl_src=a3:a0:44:7b:d8:7e,dl_dst=93:22:0c:90:c1:a0 actions=output:1
cookie=0x0, duration=2.98s, table=1, n_packets=0, n_bytes=0, idle_timeout=180, priority=2,in_port=1,dl_src=93:22:0c:90:c1:a0,dl_dst=a3:a0:44:7b:d8:7e actions=output:2
cookie=0x0, duration=610.794s, table=1, n_packets=3, n_bytes=126, priority=1 actions=CONTROLLER:65535
```
これにより、host1からhost2へのフローエントリも追加され、host2とhost1間の双方向のエントリができていることがかくにんできた。

