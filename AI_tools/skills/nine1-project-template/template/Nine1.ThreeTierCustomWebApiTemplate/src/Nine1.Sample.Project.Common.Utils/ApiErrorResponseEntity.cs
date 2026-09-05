namespace Nine1.Sample.Project.Common.Utils
{
    public class ApiErrorResponseEntity
    {
        /// <summary>
        /// 錯誤代碼
        /// </summary>
        /// <example>錯誤代碼</example>
        public string Code { get; set; }

        /// <summary>
        /// 錯誤訊息
        /// </summary>
        /// <example>錯誤訊息</example>
        public string Message { get; set; }

        /// <summary>
        /// 資料
        /// </summary>
        /// <example>null</example>
        public object? Data { get; set; }
    }
}