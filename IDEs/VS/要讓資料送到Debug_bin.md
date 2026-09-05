

## translation i18n

把資料 properties 帶出來, 然後設定 copy as always



## 怎麼讓整個資料夾都會輸出

在 Nine1.Livebuy.Common.Translations.csproj

加入

```csharp
<None Update="i18n\**\*">
    <CopyToOutputDirectory>Always</CopyToOutputDirectory>
</None>


//或

<ItemGroup>
    <None Update="clientModules.json">
    <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <Content Include="i18n\**">
    <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </Content>
</ItemGroup>
<ItemGroup>
```


原本只有
```csharp
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Nine1.Translation.Client" Version="1.1.0" />
  </ItemGroup>

  <ItemGroup>
    <None Update="build.cake">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\**\*">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\backend.general\ja-JP.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\backend.general\ms-MY.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\backend.general\th-TH.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\backend.general\zh-CN.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\backend.general\zh-HK.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\backend.general\zh-TW.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\frontend.common\en-US.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\frontend.common\ja-JP.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\frontend.common\ms-MY.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\frontend.common\th-TH.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\frontend.common\zh-CN.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\frontend.common\zh-HK.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\frontend.common\zh-TW.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="i18n\Nine1.Livebuy\i18n.manifest">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
    <None Update="translation_config.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
  </ItemGroup>

  <ItemGroup>
    <Content Include="i18n\**\*">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </Content>
  </ItemGroup>

</Project>

```