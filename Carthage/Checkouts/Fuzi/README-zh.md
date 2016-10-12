# Fuzi (斧子)

[![Build Status](https://api.travis-ci.org/cezheng/Fuzi.svg)](https://travis-ci.org/cezheng/Fuzi)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/Fuzi.svg)](https://cocoapods.org/pods/Fuzi)
[![License](https://img.shields.io/cocoapods/l/Fuzi.svg?style=flat&color=gray)](http://opensource.org/licenses/MIT)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/Fuzi.svg?style=flat)](http://cezheng.github.io/Fuzi/)
[![Twitter](https://img.shields.io/badge/twitter-@AdamoCheng-blue.svg?style=flat)](http://twitter.com/AdamoCheng)
[![Weibo](https://img.shields.io/badge/weibo-Real__Adam-red.svg)](http://weibo.com/cezheng)

> 需要支持Swift 3的版本? 请使用 [swift-3](../../tree/swift-3) branch。

**Swift实现的轻量快速的 XML/HTML 解析器。** [[文档]](http://cezheng.github.io/Fuzi/)

Mattt Thompson大神的 [Ono](https://github.com/mattt/Ono)(斧) 是iOS/OSX平台上非常好用的一个XML/HTML 解析库。用ObjectiveC实现的Ono在Swift的应用里虽然可以使用，却有诸多不便。因此鄙人参照了Ono对libxml2的封装方式，对类和方法进行了重新设计弄出了这个小库。同时修正了Ono存在的一些逻辑上和内存管理方面的bug。

> Fuzi(斧子) 大家都懂是啥意思，[Ono](https://github.com/mattt/Ono)(斧)则是`斧`这个汉字的日语读法, 因为Mattt神写出Ono是受了 [Nokogiri](http://nokogiri.org) (鋸)的启发，取了一个同类的名词向其致敬。

[English](README.md)
[日本語](README-ja.md)

## 一个简单的例子
```swift
let xml = "..."
do {
  let document = try XMLDocument(string: xml)
  
  if let root = document.root {
    // Accessing all child nodes of root element
    for element in root.children {
      print("\(element.tag): \(element.attributes)")
    }
    
    // Getting child element by tag & accessing attributes
    if let length = root.firstChild(tag:"Length", inNamespace: "dc") {
      print(length["unit"])     // `unit` attribute
      print(length.attributes)  // all attributes
    }
  }
  
  // XPath & CSS queries
  for element in document.xpath("//element") {
    print("\(element.tag): \(element.attributes)")
  }
  
  if let firstLink = document.firstChild(css: "a, link") {
    print(firstLink["href"])
  }
} catch let error {
  print(error)
}
```

## 特性
### 继承自Ono
- 借助`libxml2`实现的快速解析 
- [XPath](http://en.wikipedia.org/wiki/XPath) 和 [CSS](http://en.wikipedia.org/wiki/Cascading_Style_Sheets) 查询
- 日期和数字的自动转换
- 支持XML命名空间
- 能从`String`，`NSData` 或 `[CChar]`构建XML文档
- 全面的自动测试
- 文档覆盖率100%

### Fuzi的改进
- 遵循Swift规范的命名和API重新设计，避免了在Swift中使用Ono的很多不便
- 可以规定自动转换日期和数字的格式了
- 修正了一些bug
- 增加更多常用的HTML处理方法
- 支持获取所有类型的节点（包括文字节点，注释节点等）
- 支持更多的CSS查询类型 (今后将会支持)

## 环境

- iOS 8.0+ / Mac OS X 10.9+
- Xcode 7.0+


## 导入
### 通过[Cocoapods](http://cocoapods.org/)
您可以通过 [Cocoapods](http://cocoapods.org/) 来将 `Fuzi` 添加到您的项目中。 下面是一个示例的`Podfile`:

```ruby
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
	pod 'Fuzi', '~> 0.3.0'
end
```

配置好Podfile后执行如下命令:

```bash
$ pod install
```

### 手动导入
1. 将`Fuzi`文件夹下所有`*.swift`文件添加到您的Xcode项目中。
2. 将`libxml2`文件夹拷到你的项目路径下的某处，下称`/path/to/somewhere`。
3. 修改Xcode项目的`Build Settings`:
   1. 向`Swift Compiler - Search Paths`的`Import Paths`条目下添加`/path/to/somewhere/libxml2`。
   2. 向`Search Paths`的`Header Search Paths`条目下添加`$(SDKROOT)/usr/include/libxml2`。
   3. 向`Linking`的`Other Linker Flags`条目下添加`-lxml2`。

### 通过[Carthage](https://github.com/Carthage/Carthage)
在项目的根目录下创建名为 `Cartfile` 或 `Cartfile.private`的文件，并加入如下一行:

```
github "cezheng/Fuzi" ~> 0.3.0
```
然后执行如下命令:

```
$ carthage update
```
最后对Xcode的目标做如下设置：

1. 将Carthage编译出来的`Fuzi.framework`拖拽如目标的`General` -> `Embedded Binaries`。
2. `Build Settings`中，向`Search Paths`的`Header Search Paths`条目下添加`$(SDKROOT)/usr/include/libxml2`。


##例子
###XML
```swift
import Fuzi

let xml = "..."
do {
  // if encoding is omitted, it defaults to NSUTF8StringEncoding
  let doc = try XMLDocument(string: html, encoding: NSUTF8StringEncoding)
  if let root = document.root {
    print(root.tag)
    
    // define a prefix for a namespace
    document.definePrefix("atom", defaultNamespace: "http://www.w3.org/2005/Atom")
    
    // get first child element with given tag in namespace(optional)
    print(root.firstChild(tag: "title", inNamespace: "atom"))

    // iterate through all children
    for element in root.children {
      print("\(index) \(element.tag): \(element.attributes)")
    }
  }
  // you can also use CSS selector against XMLDocument when you feels it makes sense
} catch let error as XMLError {
  switch error {
  case .NoError: print("wth this should not appear")
  case .ParserFailure, .InvalidData: print(error)
  case .LibXMLError(let code, let message):
    print("libxml error code: \(code), message: \(message)")
  }
}
```
###HTML
`HTMLDocument` 是 `XMLDocument` 的子类。

```swift
import Fuzi

let html = "<html>...</html>"
do {
  // if encoding is omitted, it defaults to NSUTF8StringEncoding
  let doc = try HTMLDocument(string: html, encoding: NSUTF8StringEncoding)
  
  // CSS queries
  if let elementById = doc.firstChild(css: "#id") {
    print(elementById.stringValue)
  }
  for link in doc.css("a, link") {
      print(link.rawXML)
      print(link["href"])
  }
  
  // XPath queries
  if let firstAnchor = doc.firstChild(xpath: "//body/a") {
    print(firstAnchor["href"])
  }
  for script in doc.xpath("//head/script") {
    print(script["src"])
  }
  
  // Evaluate XPath functions
  if let result = doc.eval(xpath: "count(/*/a)") {
    print("anchor count : \(result.doubleValue)")
  }
  
  // Convenient HTML methods
  print(doc.title) // gets <title>'s innerHTML in <head>
  print(doc.head)  // gets <head> element
  print(doc.body)  // gets <body> element
  
} catch let error {
  print(error)
}
```

###如果觉得没必要处理异常

```swift
import Fuzi

let xml = "..."

// Don't show me the errors, just don't crash
if let doc1 = try? XMLDocument(string: xml) {
  //...
}

let html = "<html>...</html>"

// I'm sure this won't crash
let doc2 = try! HTMLDocument(string: html)
//...
```

###我想访问文字节点
不仅文字节点，你可以指定你想获取的任何类型的节点。

```swift
let document = ...
// 获取所有类型为元素，文字或注释的节点
document.root?.childNodes(ofTypes: [.Element, .Text, .Comment])
```

##从Ono转移到Fuzi
下面两个示例程序做的事情是完全一样的，通过比较能很快了解两者的异同。

[Ono示例](https://github.com/mattt/Ono/blob/master/Example/main.m)

[Fuzi示例](FuziDemo/FuziDemo/main.swift)

###访问子节点
**Ono**

```objc
[doc firstChildWithTag:tag inNamespace:namespace];
[doc firstChildWithXPath:xpath];
[doc firstChildWithXPath:css];
for (ONOXMLElement *element in parent.children) {
  //...
}
[doc childrenWithTag:tag inNamespace:namespace];
```
**Fuzi**

```swift
doc.firstChild(tag: tag, inNamespace: namespace)
doc.firstChild(xpath: xpath)
doc.firstChild(css: css)
for element in parent.children {
  //...
}
doc.children(tag: tag, inNamespace:namespace)
```
###迭代查询结果
**Ono**

查询结果实现了`NSFastEnumeration`协议。

```objc
// simply iterating through the results
// mark `__unused` to unused params `idx` and `stop`
[doc enumerateElementsWithXPath:xpath usingBlock:^(ONOXMLElement *element, __unused NSUInteger idx, __unused BOOL *stop) {
  NSLog(@"%@", element);
}];

// stop the iteration at second element
[doc enumerateElementsWithXPath:XPath usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
  *stop = (idx == 1);
}];

// getting element by index 
ONOXMLDocument *nthElement = [(NSEnumerator*)[doc CSS:css] allObjects][n];

// total element count
NSUInteger count = [(NSEnumerator*)[document XPath:xpath] allObjects].count;
```

**Fuzi**

查询结果的集合实现了Swift的 `SequenceType` 与 `Indexable`协议。

```swift
// simply iterating through the results
// no need to write the unused `idx` or `stop` params
for element in doc.xpath(xpath) {
  print(element)
}

// stop the iteration at second element
for (index, element) in doc.xpath(xpath).enumerate() {
  if idx == 1 {
    break
  }
}

// getting element by index 
if let nthElement = doc.css(css)[n] {
  //...
}

// total element count
let count = doc.xpath(xpath).count
```
###执行XPath函数
**Ono**

```objc
ONOXPathFunctionResult *result = [doc functionResultByEvaluatingXPath:xpath];
result.boolValue;    //BOOL
result.numericValue; //double
result.stringValue;  //NSString
```

**Fuzi**

```swift
if let result = doc.eval(xpath: xpath) {
  result.boolValue   //Bool
  result.doubleValue //Double
  result.stringValue //String
}
```

## 开源协议

`Fuzi` 使用MIT许可协议。详见 [LICENSE](LICENSE) 。
