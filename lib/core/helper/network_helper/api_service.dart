import 'dart:developer';

class ApiService {
  // create userSignUp method
  /*Future<SignUpResponseModel> userSignUp({
    required SignUpRequestBody signUpRequestBody,
  }) async {
    final body = signUpRequestBody.toJson();

    log('Sending SignUp request with: $body');

    final response = await Api().post(url: 'auth/signup', body: body);

    log('SignUp response data: ${response.data}');

    // تحويل الـ Map القادم من السيرفر إلى الـ Model الخاص بالـ Response
    return SignUpResponseModel.fromJson(response.data);
  }

  Future<LoginResponseModel> userLogin({
    required LoginRequestModel loginRequestBody,
  }) async {
    log('in service');
    final body = loginRequestBody.toJson();

    log('Sending Login request with: $body');

    final response = await Api().post(url: 'auth/login', body: body);

    log('Login response data: ${response.data}');

    // تحويل الـ Map القادم من السيرفر إلى الـ Model الخاص بالـ Response
    return LoginResponseModel.fromJson(response.data);
  }

  Future<ProfileResponseModel> userProfile({String? token}) async {
    log('Fetching profile with token: $token');

    final responseData = await Api().get(Url: 'profile', token: token);

    log('Profile response data: $responseData');

    return ProfileResponseModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<CampaignListResponseModel> getCampaigns() async {
    const page = 1;
    const pageSize = 10;

    log('Fetching campaigns page=$page pageSize=$pageSize');

    final responseData = await Api().get(
      Url: 'campaigns?page=$page&pageSize=$pageSize',
      token: null,
    );
    final CampaignListResponseModel campaignListResponseModel =
        CampaignListResponseModel.fromJson(responseData);
    log('Campaigns response data: $responseData');

    return campaignListResponseModel;
  }

  Future<CampaignListResponseModel> getCampaignsByCharity({
    required String charityId,
    int page = 1,
    int pageSize = 10,
  }) async {
    log(
      'Fetching campaigns for charity=$charityId page=$page pageSize=$pageSize',
    );

    final responseData = await Api().get(
      Url: 'charities/$charityId/campaigns?page=$page&pageSize=$pageSize',
      token: null,
    );

    final CampaignListResponseModel campaignListResponseModel =
        CampaignListResponseModel.fromJson(responseData);

    log('Campaigns by charity response data: $responseData');

    return campaignListResponseModel;
  }

  Future<CharitiesListResponseModel> getCharities() async {
    const page = 1;
    const pageSize = 10;

    log('Fetching charities page=$page pageSize=$pageSize');

    final responseData = await Api().get(
      Url: 'charities?page=$page&pageSize=$pageSize',
      token: null,
    );

    log('Charities response data: $responseData');

    return CharitiesListResponseModel.fromJson(responseData);
  }

  Future<CasesListResponseModel> getCases() async {
    const page = 1;
    const pageSize = 10;

    log('Fetching charities page=$page pageSize=$pageSize');

    final responseData = await Api().get(
      Url: 'cases?page=$page&pageSize=$pageSize',
      token: null,
    );

    log('Charities response data: $responseData');

    return CasesListResponseModel.fromJson(responseData);
  }

  Future<CasesListResponseModel> getCasesByCharity({
    required String charityId,
    int page = 1,
    int pageSize = 10,
  }) async {
    log('Fetching cases for charity=$charityId page=$page pageSize=$pageSize');

    final responseData = await Api().get(
      Url: 'charities/$charityId/cases?page=$page&pageSize=$pageSize',
      token: null,
    );

    log('Cases by charity response data: $responseData');

    return CasesListResponseModel.fromJson(responseData);
  }

  Future<HomeResponseModel> getHome() async {
    log('Fetching home data');

    final responseData = await Api().get(Url: 'home', token: null);

    log('Home response data: $responseData');

    return HomeResponseModel.fromJson(responseData);
  }

  Future<CaseResponseModel> getCaseById({required String id}) async {
    log('Fetching case by id: $id');

    final responseData = await Api().get(Url: 'cases/$id', token: null);

    log('Case by id response data: $responseData');

    return CaseResponseModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<CampaignResponseModel> getCampaignById({required String id}) async {
    log('Fetching campaign by id: $id');

    final responseData = await Api().get(Url: 'campaigns/$id', token: null);

    log('Campaign by id response data: $responseData');

    return CampaignResponseModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<CharityResponseModel> getCharityById({required String id}) async {
    log('Fetching charity by id: $id');

    final responseData = await Api().get(Url: 'charities/$id', token: null);

    log('Charity by id response data: $responseData');

    return CharityResponseModel.fromJson(responseData as Map<String, dynamic>);
  }
  */
}
