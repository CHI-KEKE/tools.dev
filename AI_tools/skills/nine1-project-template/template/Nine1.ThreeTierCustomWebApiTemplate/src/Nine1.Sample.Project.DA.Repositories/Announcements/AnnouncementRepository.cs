using Nine1.Sample.Project.BL.BE.Accouncements;
using Nine1.Sample.Project.BL.BE.Accouncements.Enum;

namespace Nine1.Sample.Project.DA.Repositories.Announcements
{
    public class AnnouncementRepository : IAnnouncementRepository
    {
        /// <summary>
        /// 假資料
        /// </summary>
        private static List<Announcement> announcementData { get; set; } = new List<Announcement>
        {
            { new Announcement { Id = 1, AnnounceDateTime = null, Title = "公告標題一", Content = "公告一內容", Status = 1, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser1", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 2, AnnounceDateTime = DateTime.Now, Title = "公告標題二", Content = "公告二內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser2", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 3, AnnounceDateTime = DateTime.Now, Title = "公告標題三", Content = "公告三內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser3", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 4, AnnounceDateTime = DateTime.Now, Title = "公告標題四", Content = "公告四內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser4", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 5, AnnounceDateTime = DateTime.Now, Title = "公告標題五", Content = "公告五內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser5", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 6, AnnounceDateTime = DateTime.Now, Title = "公告標題六", Content = "公告六內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser6", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 7, AnnounceDateTime = DateTime.Now, Title = "公告標題七", Content = "公告七內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser7", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 8, AnnounceDateTime = DateTime.Now, Title = "公告標題八", Content = "公告八內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser8", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 9, AnnounceDateTime = null, Title = "公告標題九", Content = "公告一內容", Status = 1, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser9", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 10, AnnounceDateTime = DateTime.Now, Title = "公告標題十", Content = "公告十內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser10", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 11, AnnounceDateTime = DateTime.Now, Title = "公告標題十一", Content = "公告十一內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser11", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 12, AnnounceDateTime = DateTime.Now, Title = "公告標題十二", Content = "公告十二內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser12", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 13, AnnounceDateTime = DateTime.Now, Title = "公告標題十三", Content = "公告十三內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser13", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 14, AnnounceDateTime = DateTime.Now, Title = "公告標題十四", Content = "公告十四內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser14", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 15, AnnounceDateTime = DateTime.Now, Title = "公告標題十五", Content = "公告十五內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser15", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 16, AnnounceDateTime = DateTime.Now, Title = "公告標題十六", Content = "公告十六內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser16", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 17, AnnounceDateTime = null, Title = "公告標題十七", Content = "公告十七內容", Status = 1, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser17", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 18, AnnounceDateTime = DateTime.Now, Title = "公告標題十八", Content = "公告十八內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser18", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 19, AnnounceDateTime = DateTime.Now, Title = "公告標題十九", Content = "公告十九內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser19", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 20, AnnounceDateTime = DateTime.Now, Title = "公告標題二十", Content = "公告二十內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser20", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 21, AnnounceDateTime = DateTime.Now, Title = "公告標題二一", Content = "公告二一內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser21", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 22, AnnounceDateTime = DateTime.Now, Title = "公告標題二二", Content = "公告二二內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser22", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 23, AnnounceDateTime = DateTime.Now, Title = "公告標題二三", Content = "公告二三內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser23", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }},
            { new Announcement { Id = 24, AnnounceDateTime = DateTime.Now, Title = "公告標題二四", Content = "公告二四內容", Status = 0, UpdatedUserList = new List<AnnouncementUpdatedUser> { new AnnouncementUpdatedUser { UpdatedUser = "TestUser24", UpdatedDateTime = DateTime.Now }}, ValidFlag = true }}
        };

        /// <summary>
        /// 新增公告
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public async Task<long> CreateAnnouncement(Announcement data)
        {
            announcementData.Add(data);

            return data.Id;
        }

        public async Task<long> DeleteAnnouncement(long id)
        {
            var queryData = announcementData.Where(x => x.Id == id && x.ValidFlag == true).FirstOrDefault();

            queryData.ValidFlag = false;
            var updatedInfo = new AnnouncementUpdatedUser()
            {
                UpdatedUser = "system",
                UpdatedDateTime = DateTime.Now
            };

            queryData.UpdatedUserList.Add(updatedInfo);           

            return id;
        }

        /// <summary>
        /// Enable 公告
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public async Task<long> EnableAnnouncement(long id)
        {
            var queryData = announcementData.Where(x => x.Id == id && x.ValidFlag == true).FirstOrDefault();

            queryData.Status = (long)AnnouncementStatusEnum.Announced;
            queryData.AnnounceDateTime = DateTime.Now;
            var updatedInfo = new AnnouncementUpdatedUser()
            {
                UpdatedUser = "system",
                UpdatedDateTime = DateTime.Now
            };

            queryData.UpdatedUserList.Add(updatedInfo);

            return id;
        }

        /// <summary>
        /// 查詢公告列表
        /// </summary>
        /// <param name="limit"></param>
        /// <param name="offset"></param>
        /// <returns></returns>
        public async Task<Tuple<int, IEnumerable<Announcement>>> GetAnnouncement(int limit, int offset)
        {
            var queryData = announcementData.Where(x => x.ValidFlag == true)
                                        .OrderByDescending(x => x.Id)
                                        .Skip(offset)
                                        .Take(limit);
            var total = announcementData.Where(x => x.ValidFlag == true).Count();

            return new Tuple<int, IEnumerable<Announcement>>(total, queryData);
        }

        /// <summary>
        /// 查詢公告
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public async Task<Announcement> GetAnnouncementById(long id)
        {
            return announcementData?.Where(x => x.Id == id
                                                 && x.ValidFlag == true)?.FirstOrDefault();
        }

        /// <summary>
        /// 修改公告
        /// </summary>
        /// <param name="id"></param>
        /// <param name="data"></param>
        /// <returns></returns>
        public async Task<long> UpdateAnnouncement(long id, UpdateAnnouncementRequestEntity data)
        {
            var queryData = announcementData.Where(x => x.Id == id && x.ValidFlag == true).FirstOrDefault();
            queryData.Title = data.Title;
            queryData.Content = data.Content;
            queryData.Status = (long)data.Status;
            queryData.AnnounceDateTime = data.Status == AnnouncementStatusEnum.Announced ? DateTime.Now : null;
            var updatedInfo = new AnnouncementUpdatedUser()
            {
                UpdatedUser = "system",
                UpdatedDateTime = DateTime.Now
            };

            queryData.UpdatedUserList.Add(updatedInfo);
            
            return id;
        }
    }
}