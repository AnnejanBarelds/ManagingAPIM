param apimName string

param name string

param value string

resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' existing = {
  name: apimName
  resource namedValue 'namedValues@2023-03-01-preview' = {
    name: name
    properties: {
      displayName: name
      value: value
    }
  }
}
