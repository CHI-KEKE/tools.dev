using Nine1.Sample.Project.BL.BE.Accouncements;
using Nine1.Sample.Project.BL.BE.Accouncements.Enum;
using Nine1.Sample.Project.Common.Utils;
using Nine1.Sample.Project.Common.Utils.ServerEntity.Entity;
using Nine1.Sample.Project.Common.Utils.ServerEntity.Enum;
using Nine1.Sample.Project.DA.Repositories.Announcements;

namespace Nine1.Sample.Project.BL.Services.Announcements
{
    public class AnnouncementService : IAnnouncementService
    {
        /// <summary>
        /// IAnnouncementRepository
        /// </summary>
        protected readonly IAnnouncementRepository _announcementRepository;

        /// <summary>
        /// AnnouncementService
        /// </summary>
        /// <param name="channelRepository">IChannelRepository</param>
        public AnnouncementService(IAnnouncementRepository announcementRepository)
        {
            this._announcementRepository = announcementRepository;
        }

        /// <summary>
        /// 新增公告
        /// </summary>
        /// <param name="entity"></param>
        /// <returns></returns>
        public async Task<CreateAnnouncementResponseEntity> CreateAnnouncement(CreateAnnouncementRequestEntity entity)
        {
            // 因為是 in memory sample，沒有 DB 自動 +1 的 index，所以寫死撈最多 100 筆取其中最大的 id
            (int total, IEnumerable<Announcement> AnnouncementList) = await _announcementRepository.GetAnnouncement(100, 0);

            var data = new Announcement()
            {
                Id = AnnouncementList.OrderBy(x => x.Id).Last().Id + 1,
                AnnounceDateTime = entity.Status == AnnouncementStatusEnum.Announced ? DateTime.Now : null,
                Title = entity.Title,
                Content = entity.Content,
                Status = (long)entity.Status,
                UpdatedUserList = new List<AnnouncementUpdatedUser>()
                {
                    new AnnouncementUpdatedUser()
                    {
                        UpdatedUser = "system",
                        UpdatedDateTime = DateTime.Now
                    }
                }
            };

            await _announcementRepository.CreateAnnouncement(data);

            return new CreateAnnouncementResponseEntity()
            {
                Id = data.Id
            };
        }

        /// <summary>
        /// 刪除公告
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public async Task<long> DeleteAnnouncement(long id)
        {
            var queryData = await _announcementRepository.GetAnnouncementById(id);

            if (queryData == null)
            {
                throw new ApplicationApiException(ApplicationApiExceptionEnum.InvalidOperation, "不存在此公告");
            }           

            await _announcementRepository.DeleteAnnouncement(id);

            return queryData.Id;
        }

        /// <summary>
        /// Enable 公告
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public async Task<long> EnableAnnouncement(long id)
        {
            var queryData = await _announcementRepository.GetAnnouncementById(id);

            if (queryData == null)
            {
                throw new ApplicationApiException(ApplicationApiExceptionEnum.InvalidOperation, "不存在此公告");
            }

            if (queryData.Status == (long)AnnouncementStatusEnum.Announced)
            {
                throw new ApplicationApiException(ApplicationApiExceptionEnum.InvalidOperation, "此公告已公告");
            }

            await _announcementRepository.EnableAnnouncement(id);

            return queryData.Id;
        }

        /// <summary>
        /// 查詢公告列表
        /// </summary>
        /// <param name="limit"></param>
        /// <param name="offset"></param>
        /// <returns></returns>
        public async Task<ListResultEntity<GetAnnouncementResponseEntity>> GetAnnouncement(int limit, int offset)
        {
            (int total, IEnumerable<Announcement> announcementList) = await this._announcementRepository.GetAnnouncement(limit, offset);
            var mappingDataList = new List<GetAnnouncementResponseEntity>();

            // mapping data
            foreach (var item in announcementList)
            {
                var mappingData = new GetAnnouncementResponseEntity()
                {
                    Id = item.Id,
                    AnnounceDateTime = item.AnnounceDateTime.HasValue ? item.AnnounceDateTime : null,
                    Title = item.Title,
                    Status = (AnnouncementStatusEnum)item.Status,
                    UpdatedUserList = item.UpdatedUserList
                };

                mappingDataList.Add(mappingData);
            }

            var result = new ListResultEntity<GetAnnouncementResponseEntity>
            {
                List = mappingDataList,
                TotalCount = total,
                PageCount = (total + (limit - 1)) / limit
            };

            return result;

        }

        /// <summary>
        /// 查詢公告
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public async Task<GetAnnouncementByIdResponseEntity> GetAnnouncementById(long id)
        {
            var queryData = await this._announcementRepository.GetAnnouncementById(id);
            if (queryData != null)
            {
                // mapping data
                var result = new GetAnnouncementByIdResponseEntity()
                {
                    Id = queryData.Id,
                    AnnounceDateTime = queryData.AnnounceDateTime.HasValue ? queryData.AnnounceDateTime : null,
                    Title = queryData.Title,
                    Content = queryData.Content,
                    Status = (AnnouncementStatusEnum)queryData.Status,
                    UpdatedUserList = queryData.UpdatedUserList
                };

                return result;
            }
            else
            {
                throw new ApplicationApiException(ApplicationApiExceptionEnum.InvalidOperation, "不存在此公告");
            }
        }

        /// <summary>
        /// 修改公告
        /// </summary>
        /// <param name="id"></param>
        /// <param name="entity"></param>
        /// <returns></returns>
        public async Task<long> UpdateAnnouncement(long id, UpdateAnnouncementRequestEntity entity)
        {
            var queryData = await _announcementRepository.GetAnnouncementById(id);

            if (queryData == null)
            {
                throw new ApplicationApiException(ApplicationApiExceptionEnum.InvalidOperation, "不存在此公告");
            }

            await _announcementRepository.UpdateAnnouncement(id, entity);
            return queryData.Id;
        }
    }
}