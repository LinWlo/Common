# ZStack

## 1. SR-IOV

### 1.1. 什么是SR-IOV

- 单根 I/O 虚拟化(SR-IOV)是一种规范，它允许单个 PCI Express(PCIe)设备向主机系统呈现多个独立的 PCI 设备，称为 虚拟功能 (VF)。这样的每个设备：
	```python
	提供与原始 PCI 设备相同的或类似的服务。
	出现在主机 PCI 总线的不同地址上。
	可使用 VFIO 分配功能分配到不同的虚拟机。
	```
- 例如，单个具有 SR-IOV 的网络设备可以向多个虚拟机显示 VF。虽然所有 VF 都使用相同的物理卡、相同的网络连接和相同的网线，但每个虚拟机都直接控制其自己的硬件网络设备，并且不使用主机的额外资源。

### 1.2. SR-IOV 的工作原理

- SR-IOV 功能引进了以下 PCI 功能：
	```python
	物理功能(PF)：为主机提供设备（如网络）功能的 PCIe 功能，但也可以创建和管理一组 VF。每个具有 SR-IOV 功能的设备都有一个或多个 PF。
	虚拟功能(VF)：充当独立设备的轻量级 PCIe 功能。每个 VF 都是从 PF 中派生的。一个设备可依赖于设备硬件的最大 VF 数。每个 VF 每次只能分配给一个虚拟机，但虚拟机可以分配多个 VF。
	VM 将 VF 识别为虚拟设备。例如，由 SR-IOV 网络设备创建的 VF 显示为分配给虚拟机的网卡，其方式与主机系统上显示的物理网卡相同。
	```
	
### 1.3. SR-IOV的优缺点

- 优点：
	```python
	1. 提高的性能,减少主机 CPU 和内存资源使用量
	例如，作为 vNIC 附加到虚拟机的 VF 性能几乎与物理 NIC 相同，并且优于半虚拟化或模拟的 NIC。特别是，当多个 VF 在单个主机上同时使用时，其性能优势可能非常显著。
	```
- 缺点
	```python
	1. 要修改 PF 的配置，您必须首先将 PF 公开的 VF 数量改为零。因此，您还需要将这些 VF 提供的设备从分配给虚拟机的设备中删除。
	2. 附加了 VFIO 分配设备的虚拟机（包括 SR-IOV VF）无法迁移到另一台主机。在某些情况下，您可以通过将分配的设备与模拟的设备进行配对来临时解决这个限制。例如，您可以将分配的网络 VF 绑定 到模拟的 vNIC 中，并在迁移前删除 VF。
	3. 分配了 VFIO 的设备需要固定虚拟机内存，这会增加虚拟机的内存消耗，并防止在虚拟机上使用内存膨胀。
	```
	
### 1.4. SR-IOV 网络设备附加到虚拟机

- 要将 SR-IOV 网络设备附加到 Intel 或 AMD 主机上的虚拟机(VM)，您必须从主机上支持 SR-IOV 的网络接口创建一个虚拟功能(VF)，并将 VF 作为设备分配给指定虚拟机。

#### 1.4.1. 先决条件

- 主机的 CPU 和固件支持 I/O 内存管理单元(IOMMU)：
	```python
	1. 如果使用 Intel CPU，它必须支持 Intel 的直接 I/O 虚拟化技术(VT-d)。
	2. 如果使用 AMD CPU，则必须支持 AMD-Vi 功能。
	3. 主机系统使用访问控制服务(ACS)来为 PCIe 拓扑提供直接内存访问(DMA)隔离。
	```
- 物理网络设备支持 SR-IOV：
	```python
	# 要验证系统上的任何网络设备是否支持 SR-IOV，请使用 lspci -v 命令，并在输出中查找 单根 I/O 虚拟化(SR-IOV)
	# 1. 查看主机中存在的网卡：
	lspci | grep -i Ethernet
	# 2. 查看支持SR-IOV的网卡,存在SR-IOV能力则表示支持
	lspci -s 06:00.2 -v  | grep -i SR-IOV
	# 查看网口在哪张网卡上,与网卡设备编号对应：
	ethtool -i enp6s0f2 | grep bus-info
	```
- 要使 SR-IOV 设备分配正常工作，必须在主机 BIOS 和内核中启用 IOMMU 功能
	- 内核中启用IOMMU功能，ARM平台称为SMMU：
		```python
		# 1. 手动开启，grub配置文件中加入参数：
		vim /etc/default/grub
		# GRUB_CMDLINE_LINUX="intel_iommu=on,iommu=pt"
		# 更新grub并重启系统
		update-grub
		update-grub2
		grub2-mkconfig -o /boot/grub/grub.cfg
		# 2. 通过命令加入参数后重启系统
		grubby --args="intel_iommu=on iommu=pt" --update-kernel=ALL
		# 3. 通过云平台界面开启后重启系统：
		点击：资源中心--硬件设施--物理机--物理机总览页面--IOMMU启用状态
		```
	- BIOS中启用IOMMU支持，ARM平台称为SMMU：
		```python
		# 1. 进入biso，依次选择：
		Advanced--Processor Configuration--Intel(R) VT for Directed I/O
		# 修改为Enabled,保存重启
		```
		
#### 1.4.2. SR-IOV 网络设备附加到虚拟机流程

- 手动添加：
	- 查看网络设备可使用的最大 VF 数：`cat /sys/class/net/eth1/device/sriov_totalvfs`    # eth1为支持SR-IOV的网口
	- 创建虚拟功能(VF)：`echo 2 > /sys/class/net/eth1/device/sriov_numvfs`  # VF-number小于等于最大VF数
	- 确认是否添加成功：
		- `lspci | grep Ethernet`：会看到多出2张带`Virtual Function`的网卡
		- `ip a`：也能看到多出2个网口`eth1v0`和`ethv1`
- 云平台添加：
	- 点击：资源中心--硬件设施--物理机--物理机关联资源页面--物理网卡，选择可虚拟化的物理网卡，点击SR-IOV切割
	- 创建二层网络（选择已切割的网口并勾选SR-IOV）--创建三层网络(选择启用了SR-IOV的二层网络)--创建虚拟机（勾选启用了SR-IOV的三层网络并勾选SR-IOV）
	- 创建好虚拟机后查看网卡，带有Virtual Function：`lspci | grep Ethernet`











