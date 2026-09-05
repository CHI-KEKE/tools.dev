using Nine1.Sample.Project.Common.Utils.ServerEntity.Enum;

namespace Nine1.Sample.Project.Common.Utils.ServerEntity.Entity;

/// <summary>
/// ApplicationApiException
/// </summary>
public class ApplicationApiException : Exception
{
    /// <summary>
    /// ErrorCode
    /// </summary>
    private string _errorCode;

    /// <summary>
    /// ApplicationApiException
    /// </summary>
    /// <param name="errorCode">string</param>
    /// <param name="errorMessage">string</param>
    public ApplicationApiException(string errorCode, string errorMessage) : base(errorMessage)
    {
        this._errorCode = errorCode;
    }

    /// <summary>
    /// ApplicationApiException
    /// </summary>
    /// <param name="errorCode">string</param>
    /// <param name="errorMessage">string</param>
    public ApplicationApiException(ApplicationApiExceptionEnum errorCode, string errorMessage) : base(errorMessage)
    {
        this._errorCode = errorCode.ToString();
    }

    /// <summary>
    /// ErrorCode
    /// </summary>
    public string ErrorCode
    {
        get { return this._errorCode; }
        set { this._errorCode = value; }
    }
}