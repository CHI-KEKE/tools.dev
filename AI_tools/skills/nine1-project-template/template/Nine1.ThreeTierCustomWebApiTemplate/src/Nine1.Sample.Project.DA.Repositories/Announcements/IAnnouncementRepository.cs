using System;
using Nine1.Sample.Project.BL.BE.Accouncements;

namespace Nine1.Sample.Project.DA.Repositories.Announcements
{
    public interface IAnnouncementRepository
    {
        /// <summary>
        /// 查詢公告列表
        /// </summary>
        /// <param name="id">通路序號</param>
        /// <returns>通路資料</returns>
        Task<Tuple<int, IEnumerable<Announcement>>> GetAnnouncement(int limit, int offset);

        /// <summary>
        /// 查詢公告
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        Task<Announcement> GetAnnouncementById(long id);

        /// <summary>
        /// 新增公告
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        Task<long> CreateAnnouncement(Announcement data);

        /// <summary>
        /// 修改公告
        /// </summary>
        /// <param name="id"></param>
        /// <param name="data"></param>
        /// <returns></returns>
        Task<long> UpdateAnnouncement(long id, UpdateAnnouncementRequestEntity data);

        /// <summary>
        /// Enable 公告
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        Task<long> EnableAnnouncement(long id);

        /// <summary>
        /// 刪除公告
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        Task<long> DeleteAnnouncement(long id);
    }
}