---
title: Spring Cloud 与 Service Mesh，如何选择？
date: 2019-11-15
tags:
 - 架构
 - posts
 - java
categories: 
 - Architect
---
# Spring Cloud 与 Service Mesh，如何选择？

* [导读]()
* [Service Mesh 的优势]()
* [与 Spring Cloud 功能重叠]()
* [服务容器化]()
* [术业有专攻]()
* [语言壁垒]()

* [选择和迁移]()
* [全新的项目]()
* [Spring Cloud 项目的迁移]()
* [其他语言项目的迁移]()

* [参考文章]()

## 导读

**Spring Cloud** 基于Spring Boot开发，提供一套完整的微服务解决方案，具体包括服务注册与发现，配置中心，全链路监控，API网关，熔断器，远程调用框架，工具客户端等选项中立的开源组件，并且可以根据需求对部分组件进行扩展和替换。

**Service Mesh**，这里以Istio（目前Service Mesh具体落地实现的一种，且呼声最高）为例简要说明其功能。 Istio 有助于降低这些部署的复杂性，并减轻开发团队的压力。它是一个完全开源的服务网格，可以透明地分层到现有的分布式应用程序上。它也是一个平台，包括允许它集成到任何日志记录平台、遥测或策略系统的 API。Istio的多样化功能集使你能够成功高效地运行分布式微服务架构，并提供保护、连接和监控微服务的统一方法。

从上面的简单介绍中，Service Mesh 和 Spring Cloud 实现的功能差不多，那这两种架构应该如何选择呢？

## Service Mesh 的优势

2019 年，经过前几年的发展，Service Mesh 在国内开始大面积开花结果，互联网大厂纷纷开始走上实践道路（例如蚂蚁金服的SOFASTACK），也有大部分企业已经开始接触Service Mesh。

可以认为 Service Mesh 将是微服务的未来，是可以替换目前的事实标准 Spring Cloud 的存在，其原因，总结下来，有四个方面：

### 与 Spring Cloud 功能重叠

来简单看一下他们的功能对比：

|服务注册与发现|支持，基于Eureka，consul等组件，提供server，和Client管理               |支持，基于XDS接口获取服务信息，并依赖“虚拟服务路由表”实现服务发现                       |
|链路监控      |支持，基于Zikpin或者Pinpoint或者Skywalking实现                         |支持，基于sideCar代理模型，记录网络请求信息实现                                           |
|API网关       |支持，基于zuul或者spring-cloud-gateway实现                             |支持，基于Ingress gateway以及egress实现                                                   |
|熔断器        |支持，基于Hystrix实现                                                  |支持，基于声明配置文件，最终转化成路由规则实现                                            |
|服务路由      |支持，基于网关层实现路由转发                                           |支持，基于iptables规则实现                                                                |
|安全策略      |支持，基于spring-security组件实现，包括认证，鉴权等，支持通信加密      |支持，基于RBAC的权限模型，依赖Kubernetes实现，同时支持通信加密                            |
|配置中心      |支持，springcloud-config组件实现                                       |不支持                                                                                    |
|性能监控      |支持，基于Spring cloud提供的监控组件收集数据，对接第三方的监控数据存储 |支持，基于SideCar代理，记录服务调用性能数据，并通过metrics adapter，导入第三方数据监控工具|
|日志收集      |支持，提供client，对接第三方日志系统，例如ELK                          |支持，基于SideCar代理，记录日志信息，并通过log adapter，导入第三方日志系统                |
|工具客户端集成|支持，提供消息，总线，部署管道，数据处理等多种工具客户端SDK            |不支持                                                                                    |
|分布式事务    |支持，支持不同的分布式事务模式：JTA，TCC，SAGA等，并且提供实现的SDK框架|不支持                                                                                    |
|其他          |……                                                                   |……                                                                                      |

从上面表格中可以看到，如果从功能层面考虑，Spring Cloud与Service Mesh在服务治理场景下，有相当大量的重叠功能，从这个层面而言，为Spring Cloud向Service Mesh迁移提供了一种潜在的可能性。

### 服务容器化

在行业当前环境下，还有一个趋势，或者说是现状。越来越多的应用走在了通往应用容器化的道路上，或者在未来，容器化会成为应用部署的标准形态。而且无论哪种容器化运行环境，都天然支撑服务注册发现这一基本要求，这就导致Spring Cloud体系应用上容器的过程中，存在一定的功能重叠，有可能为后期的应用运维带来一定的影响，而Service Mesh恰恰需要依赖容器运行环境，同时弥补了容器环境所欠缺的内容（后续会具体分析）。

### 术业有专攻

从软件设计角度出发，我们一直在追求松耦合的架构，也希望做到领域专攻。例如业务开发人员希望我只要关心业务逻辑即可，不需要关心链路跟踪，熔断，服务注册发现等支撑工具的服务；而平台支撑开发人员，则希望我的代码中不要包含任何业务相关的内容。而Service Mesh的出现，让这种情况成为可能。

### 语言壁垒

目前而言Spring Cloud虽然提供了对众多协议的支持，但是受限于Java技术体系。这就要求应用需要在同一种语言下进行开发（这不一定是坏事儿），在某种情况下，不一定适用于一些工作场景。而从微服务设计考虑，不应该受限于某种语言，各个服务应该能够相互独立，大家需要的是遵循通信规范即可。而Service Mesh恰好可以消除服务间的语言壁垒，同时实现服务治理的能力。

## 选择和迁移

从上文中我们得知 Service Mesh 的各种优势，那么，如何让 Service Mesh 在我们的项目中落地呢？接下来我们分几种情况讨论下

### 全新的项目

如果是小型项目，轻业务、重流量、需求快速变化，可以参考我之前写的文章[轻量型互联网应用架构方式](http://myfjdthink.com/2019/10/11/%e8%bd%bb%e9%87%8f%e5%9e%8b%e4%ba%92%e8%81%94%e7%bd%91%e5%ba%94%e7%94%a8%e6%9e%b6%e6%9e%84%e6%96%b9%e5%bc%8f/)，语言层面选择 Node.js + Mongodb/Mysql.

如果项目属于业务复杂类型，语言层面可以选择 Java with Kotlin。

当然，全新项目，容器化是必须的。

而且如果你的工期紧张，可以考虑渐进式地推进, 先 k8s 后 Service Mesh。

先把项目服务容器话，在 k8s 上部署起来，此时已经能够享受 k8s 带来的一部分服务治理能力了。例如：

* 服务发现
* 负载均衡
* API 网关
* 服务路由
Istio 基于 k8s，项目有了 k8s 的基础，落地 Istio 也可以顺水渠成。

### Spring Cloud 项目的迁移

现存的 Spring Cloud 项目的迁移方案，可以参考这篇文章 [服务迁移之路 | Spring Cloud向Service Mesh转变](https://juejin.im/post/5ce26e266fb9a07eb67d619f)

简单来说就是先把服务容器化，然后逐步用 Service Mesh 替换 Spring Cloud 的功能。

### 其他语言项目的迁移

和上面的方案大同小异，前提条件都是先把服务容器话。

## 参考文章

[服务迁移之路 | Spring Cloud向Service Mesh转变](https://juejin.im/post/5ce26e266fb9a07eb67d619f)

[轻量型互联网应用架构方式](http://myfjdthink.com/2019/10/11/%e8%bd%bb%e9%87%8f%e5%9e%8b%e4%ba%92%e8%81%94%e7%bd%91%e5%ba%94%e7%94%a8%e6%9e%b6%e6%9e%84%e6%96%b9%e5%bc%8f/)

