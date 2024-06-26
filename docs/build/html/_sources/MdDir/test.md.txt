## 1. 稳定性测试
测试在一定系统压力及探针程序自身存在一定压力的情况下能长时间的运行，没有内存泄漏、僵尸进程、文件描述符泄漏等问题。

### 1.1. 测试环境

#### 1.1.1. 硬件环境
- 厂站探针在工作站上测试，主站探针由于需要获取主板温度，风扇转速等信息，在服务器上测试
	- 厂站探针：
      - x86：pc7 海光工作站
      - arm：浪潮工作站
	- 主站探针：
      - x86：172.30.22.40（ipmi：172.30.22.240）
      - arm：172.30.22.41（ipmi：172.30.22.241）

#### 1.1.2. 软件环境
- stress加压工具：stress-1.0.4

### 1.2. 测试方法
- 系统：经测试，在系统cpu加压至cpu仅剩1个线程空闲，内存加压至仅剩1G内存空闲的情况下，探针仍然能正常运行，不考虑更大的压力，系统按此情况加压；
- 探针：探针运行主要是采集并处理相关数据信息，且大多是周期性上报，大量的数据信息主要来自于非法外联，所以压力设计为在短时间内使探针采集并处理大量的非法外联信息（每10秒6万多条）；

### 1.3. 测试步骤
1. 清空iptables并关闭防火墙(99系统)：`iptables -L` `systemctl stop firewalld`
2. 修改配置文件：
    ```
    # /usr/share/smp/de.sh
    # vim /usr/share/smp/linx_config
    加入参数(主站探针)
    THREAD_SCNDRY=yes
	修改上报周期为30s（主站探针）：
	CFG_INTERVAL=30
	STAT_INTERVAL=30
	ACTIVE_INTERVAL=30
	COLLECTIONITEMS_INTERVAL=30
	
	修改上报周期为30s（厂站探针）
    PORT_INTERVAL=30
	CD_INTERVAL=30
	
    # /usr/share/smp/en.sh
    # /etc/init.d/linx_smpd restart
	
	配置文件中添加2000个白名单：
	# wget http://172.30.22.24/02_Dev/add_whiltelist.sh ：下载add_whiltelist.sh脚本
	# bash add_whiltelist.sh   # 运行脚本，根据提示输入20
    ```
3. 给测试机加压至系统cpu空闲线程数为1，内存空闲数为1G：
   - 安装stress-1.0.4：
     - `wget http://172.30.28.5/testdata/02-%e6%b5%8b%e8%af%95%e5%b7%a5%e5%85%b7/stress/stress-1.0.4.tar.gz`
     - tar -xvf stress-1.0.4.tar.gz && cd stress-1.0.4
     - ./configure && make && make install
   - 获取总的cpu线程数量：
   	 - `total_cpu=`cat /proc/cpuinfo  | grep processor | wc -l``
   - 获取系统空闲内存数量：
     - `total_mem=`free -k | grep -E "Mem|内存" | awk '{print $2}'``
     - `used_mem=`free -k | grep -E "Mem|内存" | awk '{print $3}'``
     - `free_mem=`echo "scale=3;($total_mem-$used_mem)" | bc``
	- 给cpu加压，使系统仅剩1个线程空闲; 给内存加压，使系统仅剩1G内存空闲：
   	 - `stress --cpu $(($total_cpu-2)) --vm 1 --vm-bytes $((free_mem-1024*1024))K --vm-keep`
4. 测试机中执行`top`命令查看，空闲内存（free）约在1G左右；按`1`查看各cpu线程占用情况，仅1个cpu线程空闲，其余全部占满。
5. 以大约每10秒65535次的周期触发非法外联，使探针处于高负荷状态：
   - 辅助机中执行：`time nc -z -w 1 172.30.22.114 1-65535`。# 修改为测试机ip。运行完成后查看real时间是否为10s左右，远远大于10s则换台辅助机再执行下列步骤；
   - 辅助机中执行：`while true;do nc -z -w 1 172.30.22.114 1-65535;done`  # 修改为测试机ip
6. 运行监控脚本，监控探针及主机相关资源使用情况：
   - 下载最新版到测试机：`http://172.30.28.5/testdata/06-%e8%87%aa%e5%8a%a8%e5%8c%96%e6%b5%8b%e8%af%95/00-%e8%b5%84%e6%ba%90%e7%9b%91%e6%8e%a7%e8%84%9a%e6%9c%ac/`
   - 运行监控脚本：`./system_monitor_V20240612.sh --help` // 根据使用方法监控
7. 运行24小时后，停止触发非法外联（系统加压不停止），查看资源使用情况。
	
### 1.4. 测试标准
1. 探针cpu占用会急剧上升并逐渐趋于平稳（由于系统不同，cpu占用峰值不同，只关注是否趋于平稳即可）；
2. 探针内存占用缓慢上升并逐渐趋于平稳（由于系统不同，内存占用峰值不同，只关注是否趋于平稳即可）；
3. 整个过程不会产生由于探针程序导致的僵尸进程；探针无重启（pid未改变）；文件描述符数量在一定范围内波动；
4. **停止触发非法外联，等待一段时间后，探针cpu占用恢复正常（5%及以下），内存占用恢复正常（50M及以下）**。（主要关注这一项，有些系统可能内存占用会一直增长，无法趋于平稳）

## 2. 性能测试
- 进行tcp/udp端口扫描触发非法外联，无漏报
- 打开100个终端，登录/操作无卡顿

### 2.1. 测试环境
#### 2.1.1. 硬件环境
- 厂站探针在工作站上测试，主站探针由于需要获取主板温度，风扇转速等信息，在服务器上测试
	- 厂站探针：
      - x86：pc7 海光工作站
      - arm：浪潮工作站
	- 主站探针：
      - x86：172.30.22.40（ipmi：172.30.22.240）
      - arm：172.30.22.41（ipmi：172.30.22.241）

#### 2.1.2. 软件环境
- xdotool工具

### 2.2. 测试方法
- 由于探针在有大量业务处理的时候，无法避免的cpu和内占用存会急剧升高，故性能测试不考虑探针的cpu和内存占用；
- 探针的信息采集几乎都为周期性上报，没有什么性能要求，性能方面主要是大量的非法外联的上报和大量的终端开启；
- 综上，探针性能主要测试短时间大量的非法外联信息无漏报和大量的终端操作系统无卡顿。

### 2.3. 测试步骤
- tcp/udp端口扫描
  1. 清空iptables并关闭防火墙(99系统)：`iptables -L` `systemctl stop firewalld`
  2. 配置文件中添加2000个白名单：
    ```
    下载add_whiltelist.sh脚本：wget http://172.30.22.24/02_Dev/add_whiltelist.sh
    运行脚本：bash add_whiltelist.sh   # 根据提示输入20
    ```
  3. 清空日志：`echo > /usr/share/smp/log/linx_smp_audit.log`
  4. 辅助机中执行nc命令扫描测试机tcp端口：`time  nc -z -w 1 172.30.22.114 1-65535 `  // 修改为测试机ip
  5. 扫描结束查看测试机中日志的非法外联记录条数应大于等于65535条：
     - 厂站探针：`cat /usr/share/smp/log/linx_smp_audit.log | grep "SVR TCP 5 25 172.30.22.114" | grep -v grep`
     - 主站探针：`cat /usr/share/smp/log/linx_smp_audit.log | grep "SVR 5 25 172.30.22.114" | grep -v grep`
  6. 清空日志：`echo > /usr/share/smp/log/linx_smp_audit.log`
  7. 辅助机中执行脚本扫描测试机udp端口：
     - 下载脚本：`wget http://172.30.28.5/testdata/06-%e8%87%aa%e5%8a%a8%e5%8c%96%e6%b5%8b%e8%af%95/%e4%b8%bb%e7%ab%99%e6%80%a7%e8%83%bd%e6%b5%8b%e8%af%95%e8%84%9a%e6%9c%ac/scan.py`
     - 运行脚本：`sudo ./scan.py -i 0.01 -H 172.30.22.114 -m udp -r 1-65535`  // 修改为测试机ip
  8. 扫描结束查看测试机中日志的非法外联记录条数应大于等于65535条：
     - 厂站探针：`cat /usr/share/smp/log/linx_smp_audit.log | grep "SVR UDP 5 25 172.30.22.114" | grep -v grep`
     - 主站探针：`cat /usr/share/smp/log/linx_smp_audit.log | grep "SVR 5 25 172.30.22.114" | grep -v grep`
- 多终端操作：
  1. 软件源下载xdotool工具
  2. 下载脚本：`wget http://172.30.22.24/xdotool.sh`
  3. 测试机中运行脚本，开启500个终端，并依次在终端中执行命令：`./xdotool.sh 500`
  4. 等待终端开启完毕：`ps -ef | grep lcm_script | wc -l`查看进程数量大于等于1000个
  5. ssh登录测试机无卡顿，操作流畅，模拟器中正常上报操作输入和回显信息
  6. 测试完成后关闭所有终端：`killall mate-teriminal`

### 2.4. 测试标准
1. 短时间内大量触发非法外联，探针无漏报；
2. 开启500个终端，系统无卡顿，报文正常上报。
