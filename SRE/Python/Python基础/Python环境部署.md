# Python 介绍

> Life is short, I need python（人生苦短，我用 python ！）

## Python 起源

Python 的作者是著名的"**龟叔**" Guido van Rossum （吉多.范罗苏姆），1989 年，龟叔为了打发无聊的圣诞节，决心开发一个新的**解释程序**，作为 ABC 的一种继承。于是便开始编写 Python。

<img src="Python环境部署/龟叔.png" alt="img-龟叔" style="zoom: 80%;" />

**ABC** 是由吉多参加设计的一种教学语言，就吉多本人看来，ABC 这种语言非常优美和强大，是**专门为非专业程序员设计的**。但是 ABC 并没有成功。**Guido** 本人看来，**ABC** 失败的原因是高级语言为时过早，并且平台迁移能力弱，难以添加新功能，仅仅专注于编程初学者，没有把有经验的编程人员纳入其中，在 **Python** 中解决了这些问题，让拓展模块的编写非常容易，并且可以在多平台进行运行....

Python 的意思是蟒蛇，是取自英国 20 世纪 70 年代首播的电视喜剧《蒙提.派森干的飞行马戏团》(Monty Python’s Flying Circus)，Guido 非常喜欢这个剧，所以选择 Python 作为新语言的名字。

1991 年，第一个 Python 编译器诞生。它是用 C 语言实现的，并能够调用 C 语言的库文件。

## 解释型和编译型语言

解释型语言是指在运行时由解释器逐行读取和执行源代码的语言。在这种语言中，代码不需要被提前编译成机器代码，而是直接由解释器逐行解析并执行。这使得开发过程更加灵活，程序员可以快速测试和修改代码。Python、JavaScript 和 Ruby 等都是常见的解释型语言。尽管解释型语言在开发时提供了便利，但由于逐行解释执行，通常在性能上不如编译型语言。

编译型语言则是指在执行之前，源代码需要通过编译器转换成机器代码或中间代码。这个过程通常会产生一个独立的可执行文件，运行时不再需要源代码或编译器。这种做法通常能提高程序的执行效率，因为编译后的代码可以直接在机器上运行。C、C++ 和 Go 等语言都是编译型语言。虽然编译型语言在执行速度上表现出色，但编译过程通常较长，调试和修改代码时也不如解释型语言方便。

## 编程语言排行

- [TIOBE Index](https://www.tiobe.com/tiobe-index/)
- [PYPL Index](https://pypl.github.io/PYPL.html)

<img src="Python环境部署/编程语言排行.png" alt="img-编程语言排行" style="zoom:80%;" />

## Python 应用领域

**人工智能** 

Python 是人工智能和机器学习领域的首选语言，主要得益于其简洁的语法和丰富的科学计算库。以下是几种典型的 Python 库：

- **NumPy**：支持大量的维度数组与矩阵运算，此外也针对数组运算提供了大量的数学函数库。
- **SciPy**：基于 NumPy 的科学计算库，提供了许多算法和函数，适用于数值积分与优化、线性代数、统计等科学计算任务。
- **Matplotlib**：强大的绘图库，可以生成各种图形，包括线图、散点图、柱状图等，常用于数据可视化。
- **TensorFlow**：由 Google 开发的开源深度学习框架，广泛用于构建和训练神经网络。

**云计算** 

Python 是云计算领域最火的语言之一，广泛用于构建和管理云基础设施。Python 的简洁性和可读性使得它成为开发云服务、自动化任务、数据处理脚本的理想选择。

**WEB开发** 

Python 拥有众多优秀的 Web 框架，适合快速开发高效、安全的 Web 应用程序。许多大型网站和服务都是用 Python 开发的，例如 YouTube、Dropbox、豆瓣等。以下是几种典型的 Web 框架：

- **Django**：一个高层次的 Python Web 框架，鼓励快速开发和简洁、实用的设计，是全栈框架的代表。
- **Flask**：一个轻量级的 Web 框架，强调简单性和灵活性，适合构建小型项目或微服务。

**系统运维** 

Python 是系统运维人员的必备语言。它可以用于编写脚本来自动化任务、管理服务器、处理文件和文本、与操作系统进行交互等。Python 的跨平台性使得它在不同的操作系统上都能有效发挥作用。

**金融** 

Python 在金融领域特别是量化交易和金融分析方面得到广泛应用。Python 的灵活性和丰富的金融数据分析库，使得它在金融工程领域的使用日益增多，重要性逐年提高。

**图形界面开发 (GUI)** 

Python 也可以用于开发桌面应用程序，以下是几种常用的图形界面开发库：

- **PyQt**：基于 Qt 框架的 Python 绑定，适合开发复杂的桌面应用程序。
- **WxPython**：基于 wxWidgets 的 Python GUI 库，提供了跨平台的原生控件。
- **TkInter**：Python 的标准 GUI 库，适合初学者和轻量级应用的快速开发。

## Python 实际应用

**谷歌**：Google App Engine、code.google.com、Google Earth、谷歌爬虫、Google 广告等项目都在大量使用 Python 开发。

**CIA**：美国中情局网站就是用 Python 开发的。

**NASA**：美国航天局（NASA）大量使用 Python 进行数据分析和运算。

**YouTube**：世界上最大的视频网站 YouTube 就是用 Python 开发的。

**Dropbox**：美国最大的在线云存储网站，全部用 Python 实现，每天网站处理 10 亿个文件的上传和下载。

**Instagram**：美国最大的图片分享社交网站，每天超过 3000 万张照片被分享，全部用 Python 开发的。

**Facebook**：大量的基础库均通过 Python 实现的。

**Redhat**：世界上最流行的 Linux 发行版本中的 yum 包管理工具就是用 Python 开发的。

**豆瓣**：公司几乎所有的业务均是通过 Python 开发的。

**知乎**：国内最大的问答社区，通过 Python 开发（国外 Quora）。

除上面之外，还有搜狐、金山、腾讯、盛大、网易、百度、阿里、淘宝、土豆、新浪、果壳等公司都在使用 Python 完成各种各样的任务

## Python 设计哲学

<img src="Python环境部署/Python设计哲学.png" alt="img-Python设计哲学" style="zoom:80%;" />

Python 的设计哲学与其他编程语言相比，有几个显著的不同之处：

1. **可读性优先**：
   - Python 强调代码的可读性，力求清晰明了。这与如 C++ 或 Java 等语言相比，后者往往更关注性能或复杂的语法结构。
2. **简洁性**：
   - Python 鼓励用较少的代码实现功能，通常会有简化的语法，而像 Java 这样的语言则要求更多的样板代码。
3. **动态类型**：
   - Python 是动态类型语言，变量类型在运行时决定，这与静态类型语言（如 C# 和 Java）形成鲜明对比，后者在编译时必须声明变量类型。
4. **多范式支持**：
   - Python 支持多种编程范式（如面向对象、函数式编程），而一些语言则更倾向于某一特定范式，如 Java 主要是面向对象的。
5. **强大的标准库**：
   - Python 附带了一个丰富的标准库，提供了大量现成的模块和功能，而其他语言可能需要依赖外部库或框架。
6. **社区和文化**：
   - Python 拥有一个积极的社区，强调开放和共享，鼓励用户贡献代码和文档，而其他语言的社区文化可能更加保守或封闭。

# Python 环境部署

## Python 解释器

- 打开官网：https://www.python.org/downloads
- 找到对应的版本，这里选择版本 `3.9.8`

**3.9.8 版本**下载链接：https://www.python.org/ftp/python/3.9.8/python-3.9.8-amd64.exe

<img src="Python环境部署/Python解释器下载1.png" alt="img-Python解释器下载1" style="zoom:80%;" />

<img src="Python环境部署/Python解释器下载2.png" alt="img-Python解释器下载2" style="zoom:80%;" />

打开安装包，添加环境变量，可以选择默认安装或者自定义安装（一般自定义安装主要是修改安装路径）

<img src="Python环境部署/Python解释器安装1.png" alt="img-Python解释器安装1" style="zoom:80%;" />

**注意**：必须勾选上下面的 “Add Python 3.9 to PATH”（添加到系统环境变量中）

**测试是否安装成功**

在键盘上按下 `win+R` 然后在左下弹出窗口中输入 `cmd` 回车

在 cmd 终端中输入 python，如果可以看到如下内容，说明 python 环境安装成功，并且请核对版本号是否与我们安装的一致……

```bash
C:\Users\test>python
Python 3.9.8 (tags/v3.9.8:bb3fdcf, Nov  5 2021, 20:48:33) [MSC v.1929 64 bit (AMD64)] on win32
Type "help", "copyright", "credits" or "license" for more information.
>>>
```

## Python 编辑器

Python 可用的编辑器有很多，因为编辑器只负责编写代码，实际的代码执行还是由我们刚刚安装的解释器进行编译解释。所以编写Python 代码对编辑器的要求不是很高。不过为了便于我们敲代码，我们还是要选择一些更加高级，功能更多的编辑器来使用。这样在编写代码的时候可以事半功倍

对于 Python 而言，最出名，最好用的编辑器就是 Pycharm 。我们后续学习也主要使用 Pycharm 编辑器。

### Pycharm

下载地址：http://www.jetbrains.com/pycharm/download/#section=windows

因为社区版可能会缺少部分功能，所以直接选择专业版。

**安装过程**：

1. 下载安装包并且安装
2. 使用 EaglesLab 提供的补丁工具进行激活
3. 查看设置 -> `About`

**上述操作环节较多，认真观看老师的操作~**

<img src="Python环境部署/Python编辑器-PyCharm激活.png" alt="img-Python编辑器-PyCharm激活" style="zoom:80%;" />

**创建第一个项目**

1. 点击New Project来创建一个项目，项目Name和Location可以自定义

<img src="Python环境部署/新建项目.png" alt="img-新建项目" style="zoom:80%;" />

2. 在项目名称上右键来创建一个Python File

<img src="Python环境部署/新建文件.png" alt="img-新建文件" style="zoom: 80%;" />

3. 编写第一个 Python 代码

```python
print('Hello World!')
```

然后右键 -> `Run demo.py` 来运行

<img src="Python环境部署/运行文件.png" alt="img-运行文件" style="zoom:80%;" />

```bash
# Output
C:\Users\test\PycharmProjects\pythonProject\.venv\Scripts\python.exe C:\Users\test\PycharmProjects\pythonProject\demo.py 
hello world

Process finished with exit code 0
```

### Vscode
是一款由微软开发且跨平台的免费源代码编辑器。该软件以扩展的方式支持语法高亮、代码自动补全、代码重构功能，并且内置了命令行工具和 Git 版本控制系统。
