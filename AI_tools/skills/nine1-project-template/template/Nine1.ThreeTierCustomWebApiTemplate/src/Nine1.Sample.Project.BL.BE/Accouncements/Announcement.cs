namespace Nine1.Sample.Project.BL.BE.Accouncements;

/// <summary>
/// Announcement
/// </summary>
public class Announcement
{
    /// <summary>
    /// 流水號
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// 公告時間
    /// </summary>
    public DateTime? AnnounceDateTime { get; set; }

    /// <summary>
    /// 標題
    /// </summary>
    public string Title { get; set; }

    /// <summary>
    /// 內容
    /// </summary>
    public string Content { get; set; }

    /// <summary>
    /// 狀態
    /// </summary>
    public long Status { get; set; }

    /// <summary>
    /// 更新人員清單
    /// </summary>
    public List<AnnouncementUpdatedUser> UpdatedUserList { get; set; }

    /// <summary>
    /// ValidFlag
    /// </summary>
    public bool ValidFlag { get; set; } = true;
}
