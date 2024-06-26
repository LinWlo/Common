
## 1. vim不能复制粘贴
- 永久生效
	1.  `vim /usr/share/vim/vim81/defaults.vim`
		- vim81为vim的版本
	2. 修改以下代码
		```python
		if has('mouse')
		set mouse=a  # 修改为set mouse-=a
		endif
		```
- 仅对当前文件生效
	- 在打开的文件中执行`:set mouse-=a`
- - -
- - -
## 2. vim高亮颜色设置
1. `vim /etc/vim/vimrc`
2. 取消注释`syntax on`
3. 注释掉`set background=dark`
- - -
- - -
## 3. ssh -X登陆不能打开图形化界面
- 显示：`Error: no DISPLAY environment variable specified`或`cannot connect to X server`
- 修改`/etc/ssh/sshd_config`中的`X11Forwarding no`为`yes`
- - -
- - -
## 4. 任意路径打开终端
- 安装插件：
	1. `apt install caja-open-terminal`
	2. 注销重新登陆
- - -
- - -
## 5. pip安装时卡住
- 指定了源，但依然卡住原因：下载这个库时，这个库又安装了其它的库，安装其它库时走的python自带的源
- 解决办法：修改python自带的源
	```python
	# vim /usr/lib/python3/dist-packages/setuptools/package_index.py
	# 修改index_url为自己要使用的源：
		self, index_url="https://pypi.org/simple/", hosts=('*',),
	# 在 Environment.__init__(self, *args, **kw) 下面添加如下内容，url换为要用的源：
		index_url="https://pypi.org/simple/"
	```
	
- - -
- - -
## 6. 设置默认编辑器
- 设置所有程序的默认编辑器
	- `export EDITOR=vim`
- 设置visudo的默认编辑器
	- 方法一：
			- `export VISUAL="vim"`
	- 方法二：
		- `select-editor`
- 设置systemctl edit的默认编辑器
	- 方法一：`export SYSTEMD_EDITTOR="/usr/bin/vim"`
- 上述方式对当前shell生效，将以上命令加入`.bashrc`或`/etc/profile`或`.cshrc`文件中可以永久生效
- - -
- - -
## 7. ssh登陆不能打开图形界面
	- `ssh -X`登陆后打开图形界面报错：cannot connect to X server 
		# vim /etc/ssh/sshd_config
		将如下内容修改为yes
		X11Forwarding yes
		重启ssh服务
- - -
- - -
## 8. virt-manager虚拟机没有图像显示
	- 安装spice包：`apt install spiceclientgtk`
- - -
- - -
## 9. shell脚本出现如下报错
	- `bash: warning: command substitution: ignored null byte in input`
		- 原因：不能把null byte赋值给变量
		- cmdline=`cat /proc/pid/cmdline | tr -d "\0"`
## 10. cockpit无法使用root用户登陆
- `vim /etc/cockpit/disallowed-users`，将root删除，重启服务


## redis连接报错
- `redis-cli -h 172.30.22.116 -p 6379`连接报错：“redis is runnig in protected”
  - 修改配置文件：`vim /etc/redis.conf`，修改为`protected-mode no`



## 11. 克隆或用模板新建虚拟机网卡名改变 ????????
- 原因：

