


cannot use a lambda expression as an argument to a dynamically operation without first casting it ot a delegate or expression tree type



你不能直接對 dynamic 型別使用 lambda 表達式，編譯器無法知道如何去編譯這段 LINQ 語法，因為 RewardHistoryList 是 dynamic，而不是已知的 IEnumerable<T> 或 List<T>


