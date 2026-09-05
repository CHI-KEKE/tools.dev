using Nine1.Sample.Project.BL.BE.Accouncements.Enum;

namespace Nine1.Sample.Project.BL.BE.Accouncements;

/// <summary>
/// GetAnnouncementResponseEntity
/// </summary>
public class GetAnnouncementResponseEntity
{
    /// <summary>
    /// 流水號
    /// </summary>
    /// <example>1</example>
    public long Id { get; set; }

    /// <summary>
    /// 公告時間
    /// </summary>
    /// <example>2022-01-01T00:00:00.000Z</example>
    public DateTime? AnnounceDateTime { get; set; }

    /// <summary>
    /// 標題
    /// </summary>
    /// <example>20220101 停機公告</example>
    public string Title { get; set; }

    /// <summary>
    /// 狀態
    /// </summary>
    public AnnouncementStatusEnum Status { get; set; }

    /// <summary>
    /// 更新人員清單
    /// </summary>
    public List<AnnouncementUpdatedUser> UpdatedUserList { get; set; }
}