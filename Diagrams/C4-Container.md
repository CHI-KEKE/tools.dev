Simon Brown 這位軟體架構師提出的圖解方法，他將一套系統的圖解分成 4 個層級，兼顧軟體架構的可讀性與完整性


Level 1 : Context (上下文/脈絡)
Level 2：Containers (容器)
Level 3：Components (元件/組件)
Level 4：Code (程式碼)

## Level 1 — Context

Context 是描述自家公司的「軟體系統」與「現實世界」的互動方式。


例如

使用銀行軟體系統的使用者
內部網路銀行系統
E-mail 系統
銀行內部核心系統


## Level 2 — Containers

說明目標系統中的主要容器 (Containers) 組成。容器的例子有 :

Applications
client-side-single web page
server-side API application
data stores
microservices

## Level 3 — Components

元件(Components) 會直接對應到 1 組實際的抽象化程式碼 (例如登入相關的程式碼 — Sign-in controller)。


## Level 4 — Code

Code 是程式碼的實作細節，在圖解上會使用如 UML 表示程式 Class (類別) 的互動關係。

