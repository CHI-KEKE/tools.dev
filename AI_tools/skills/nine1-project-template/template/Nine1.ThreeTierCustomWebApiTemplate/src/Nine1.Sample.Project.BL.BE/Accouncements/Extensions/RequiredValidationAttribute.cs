using System.ComponentModel.DataAnnotations;
// using Nine1.PortalExtBlazorTemplate.Shared.ServerEntity.Entity;
// using Nine1.PortalExtBlazorTemplate.Shared.ServerEntity.Enum;

// namespace Nine1.Sample.Project.BL.BE.Accouncements.Extensions;

// /// <summary>
// /// RequiredValidationAttribute
// /// </summary>
// public class RequiredValidationAttribute : ValidationAttribute
// {
//     /// <summary>
//     /// IsValid
//     /// </summary>
//     /// <param name="value">傳進來的 value</param>
//     /// <returns></returns>
//     protected override ValidationResult IsValid(object value, ValidationContext validationContext)
//     {
//         if (value == null)
//         {
//             throw new ApplicationApiException(ApplicationApiExceptionEnum.InvalidData, $"{validationContext.DisplayName} is required.");
//         }

//         var textValue = value.ToString();

//         if (string.IsNullOrWhiteSpace(textValue) == true)
//         {
//             throw new ApplicationApiException(ApplicationApiExceptionEnum.InvalidData, $"{validationContext.DisplayName} is required.");
//         }

//         return ValidationResult.Success;
//     }
// }