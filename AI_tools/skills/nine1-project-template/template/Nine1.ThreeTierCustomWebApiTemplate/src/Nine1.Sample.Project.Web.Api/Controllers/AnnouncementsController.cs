using System.ComponentModel;
using Microsoft.AspNetCore.Mvc;
using NSwag.Annotations;
using Nine1.Sample.Project.Common.Utils;
using Nine1.Sample.Project.BL.BE.Accouncements;
using Nine1.Sample.Project.BL.BE.Accouncements.Enum;
using Nine1.Sample.Project.Common.Utils.ServerEntity.Entity;
using Nine1.Sample.Project.Common.Utils.ServerEntity.Enum;
using Nine1.Sample.Project.BL.Services.Announcements;

namespace Nine1.Sample.Project.Website.Controllers;

[ApiController]
[Route("api/[controller]")]
[OpenApiTag("Announcements", Description = "公告")]
public class AnnouncementsController : ControllerBase
{

    /// <summary>
    /// IAnnouncementService
    /// </summary>
    private IAnnouncementService _announcementService;

    /// <summary>
    /// ILogger<AnnouncementController>
    /// </summary>
    private readonly ILogger<AnnouncementsController> _logger;

    /// <summary>
    /// AnnouncementController
    /// </summary>
    /// <param name="logger">ILogger<AnnouncementsController></param>    
    public AnnouncementsController(ILogger<AnnouncementsController> logger, IAnnouncementService announcementService)
    {
        this._logger = logger;
        this._announcementService = announcementService;
    }

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
    /// 查詢公告列表
    /// </summary>
    /// <remarks>
    /// 查詢公告列表
    /// </remarks>
    /// <param name="offset">從何筆開始取</param>
    /// <param name="limit">取得筆數</param>
    /// <response code="400">Bad request.</response>
    /// <response code="500">Unexpected error.</response>
    /// <returns>A list of announcements</returns>
    [HttpGet]
    [ProducesResponseType(typeof(ListResultEntity<GetAnnouncementResponseEntity>), 200)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 400)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 500)]
    public async Task<ListResultEntity<GetAnnouncementResponseEntity>> Get([FromQuery] int limit = 50, int offset = 0)
    {
        _logger.LogInformation("Get api called");

        if (limit <= 0)
        {
            throw new ApplicationApiException(ApplicationApiExceptionEnum.InvalidOperation, "Parameter: Limit must be no less than Zero");
        }

        return await this._announcementService.GetAnnouncement(limit, offset);
    }

    /// <summary>
    /// 查詢公告
    /// </summary>
    /// <remarks>
    /// 查詢公告
    /// </remarks>
    /// <param name="id">int</param>
    /// <response code="400">Bad request.</response>
    /// <response code="500">Unexpected error.</response>
    /// <returns>Data of announcement</returns>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(ActionResult<GetAnnouncementByIdResponseEntity>), 200)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 400)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 500)]
    public async Task<ActionResult<GetAnnouncementByIdResponseEntity>> Get([Description("流水號"), DefaultValue(1)] long id)
    {
        _logger.LogInformation("Get by id api called");

        return await this._announcementService.GetAnnouncementById(id);
    }

    /// <summary>
    /// 新增公告
    /// </summary>
    /// <remarks>
    /// 新增公告
    /// </remarks>
    /// <param name="entity">CreateAnnouncementRequestEntity</param>
    /// <response code="400">Bad request.</response>
    /// <response code="500">Unexpected error.</response>
    /// <returns>Announcement id</returns>    
    [HttpPost]
    [ProducesResponseType(typeof(CreateAnnouncementResponseEntity), 200)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 400)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 500)]
    public async Task<CreateAnnouncementResponseEntity> Create(CreateAnnouncementRequestEntity entity)
    {
        _logger.LogInformation("Create api called");

        return await this._announcementService.CreateAnnouncement(entity);
    }

    /// <summary>
    /// 修改公告
    /// </summary>
    /// <remarks>
    /// 修改公告
    /// </remarks>
    /// <param name="id">int</param>
    /// <param name="entity">UpdateAnnouncementRequestEntity</param>
    /// <response code="200">OK</response>
    /// <response code="400">Bad request.</response>
    /// <response code="500">Unexpected error.</response>
    /// <returns></returns>    
    [HttpPut("{id}")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 400)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 500)]
    public async Task<ActionResult> Update([Description("流水號"), DefaultValue(1)] long id, UpdateAnnouncementRequestEntity entity)
    {
        _logger.LogInformation("Update api called");

        await this._announcementService.UpdateAnnouncement(id, entity);

        return Ok();
    }

    /// <summary>
    /// Enable 公告
    /// </summary>
    /// <remarks>
    /// Enable 公告
    /// </remarks>
    /// <param name="id">int</param>
    /// <response code="200">OK</response>
    /// <response code="400">Bad request.</response>
    /// <response code="500">Unexpected error.</response>
    /// <returns>Enable 成功</returns>    
    [HttpPut("{id}/enable")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 400)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 500)]
    public async Task<ActionResult> Enable([Description("流水號"), DefaultValue(1)] long id)
    {
        _logger.LogInformation("Enable api called");

        await _announcementService.EnableAnnouncement(id);

        return Ok();
    }

    /// <summary>
    /// 刪除公告
    /// </summary>
    /// <remarks>
    /// 刪除公告
    /// </remarks>
    /// <param name="id">int</param>
    /// <response code="200">OK</response>
    /// <response code="400">Bad request.</response>
    /// <response code="500">Unexpected error.</response>
    /// <returns></returns>    
    [HttpDelete("{id}")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 400)]
    [ProducesResponseType(typeof(ApiErrorResponseEntity), 500)]
    public async Task<ActionResult> Delete([Description("流水號"), DefaultValue(1)] long id)
    {
        _logger.LogInformation("Delete api called");

        await _announcementService.DeleteAnnouncement(id);

        var queryData = announcementData.Where(x => x.Id == id
                                                 && x.ValidFlag == true).FirstOrDefault();

        if (queryData == null)
        {
            throw new ApplicationApiException(ApplicationApiExceptionEnum.InvalidOperation, "不存在此公告");
        }

        queryData.ValidFlag = false;

        var updatedInfo = new AnnouncementUpdatedUser()
        {
            UpdatedUser = "system",
            UpdatedDateTime = DateTime.Now
        };

        queryData.UpdatedUserList.Add(updatedInfo);

        return Ok();
    }
}
