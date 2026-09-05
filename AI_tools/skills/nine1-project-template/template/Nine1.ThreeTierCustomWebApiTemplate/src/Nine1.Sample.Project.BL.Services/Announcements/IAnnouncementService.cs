using System;
using Nine1.Sample.Project.BL.BE.Accouncements;
using Nine1.Sample.Project.Common.Utils;

namespace Nine1.Sample.Project.BL.Services.Announcements
{
    public interface IAnnouncementService
    {
        /// <summary>
        /// 查詢公告列表
        /// </summary>
        /// <returns></returns>
        Task<ListResultEntity<GetAnnouncementResponseEntity>> GetAnnouncement(int limit, int offset);

        /// <summary>
        /// 查詢公告
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        Task<GetAnnouncementByIdResponseEntity> GetAnnouncementById(long id);

        /// <summary>
        /// 新增公告
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        Task<CreateAnnouncementResponseEntity> CreateAnnouncement(CreateAnnouncementRequestEntity entity);

        /// <summary>
        /// 修改公告
        /// </summary>
        /// <param name="id"></param>
        /// <param name="entity"></param>
        /// <returns></returns>
        Task<long> UpdateAnnouncement(long id, UpdateAnnouncementRequestEntity entity);

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