using System.ComponentModel.DataAnnotations;
using Nine1.Sample.Project.BL.BE.Accouncements.Enum;

namespace Nine1.Sample.Project.BL.BE.Accouncements;

/// <summary>
/// UpdateAnnouncementRequestEntity
/// </summary>
public class UpdateAnnouncementRequestEntity
{
    /// <summary>
    /// 標題
    /// </summary>
    /// <example>20220101 停機公告</example>
    // [RequiredValidationAttribute]
    [Required]
    public string Title { get; set; }

    /// <summary>
    /// 內容
    /// </summary>
    /// <example>公告內容</example>
    // [RequiredValidationAttribute]
    [Required]
    public string Content { get; set; }

    /// <summary>
    /// 狀態
    /// </summary>
    // [RequiredValidationAttribute]
    [Required]
    public AnnouncementStatusEnum Status { get; set; }
}