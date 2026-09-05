namespace Nine1.Sample.Project.Common.Utils
{
    /// <summary>
    /// ListResultEntity
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public class ListResultEntity<T>
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="ListResultEntity{T}" /> class.
        /// </summary>
        public ListResultEntity()
        {
            this.List = new List<T>();
        }

        /// <summary>
        /// 查詢結果清單
        /// </summary>
        public IEnumerable<T> List { get; set; }

        /// <summary>
        /// 總頁數
        /// </summary>
        /// <example>5</example>
        public int PageCount { get; set; }

        /// <summary>
        /// 總筆數
        /// </summary>
        /// <example>100</example>
        public int TotalCount { get; set; }
    }
}