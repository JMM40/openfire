<%@ page import="org.jivesoftware.util.BeanUtils,
                 org.jivesoftware.util.JiveGlobals,
                 org.jivesoftware.util.LocaleUtils,
                 org.jivesoftware.util.ParamUtils" %>
<%@ page import="org.jivesoftware.wildfire.XMPPServer"%>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>

<%@ taglib uri="http://java.sun.com/jstl/core_rt" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jstl/fmt_rt" prefix="fmt" %>
<jsp:useBean id="vcardBean" scope="session" class="org.jivesoftware.admin.LdapUserProfile" />  

<%
	// Redirect if we've already run setup:
	if (!XMPPServer.getInstance().isSetupMode()) {
        response.sendRedirect("setup-completed.jsp");
        return;
    }
%>

<%
    // Get parameters
    String serverType = ParamUtils.getParameter(request, "serverType");
    // Server type should never be null, but if it is, assume "other"
    if (serverType == null) {
        serverType = "other";
    }

    // Determine the right default values based on the the server type.
    String defaultUsernameField = JiveGlobals.getXMLProperty("ldap.usernameField");
    String defaultSearchFields = JiveGlobals.getXMLProperty("ldap.searchFields");
    String defaultSearchFilter = JiveGlobals.getXMLProperty("ldap.searchFilter");
    if (serverType.equals("activedirectory")) {
        if (defaultUsernameField == null) {
            // Initialize vCard mappings
            vcardBean.initForActiveDirectory();
        }
        if (defaultUsernameField == null) {
            defaultUsernameField = "sAMAccountName";
            // Initialize vCard mappings
        }
        if (defaultSearchFilter == null) {
            defaultSearchFilter = "(objectClass=organizationalPerson)";
        }
    }
    else {
        if (defaultUsernameField == null) {
            // Initialize vCard mappings
            vcardBean.initForOpenLDAP();
        }
        if (defaultUsernameField == null) {
            defaultUsernameField = "uid";
        }
    }

    String usernameField = defaultUsernameField;
    String searchFields = defaultSearchFields;
    String searchFilter = defaultSearchFilter;

    Map<String, String> errors = new HashMap<String, String>();

    boolean save = request.getParameter("save") != null;
    if (save) {
        usernameField = ParamUtils.getParameter(request, "usernameField");
        if (usernameField == null) {
            errors.put("username", LocaleUtils.getLocalizedString("setup.ldap.user.username_field_error"));
        }
        searchFields = ParamUtils.getParameter(request, "searchFields");
        searchFilter = ParamUtils.getParameter(request, "searchFilter");
        // Set the properties to the vCard bean with the user input
        BeanUtils.setProperties(vcardBean, request.getParameterMap());

        // Save settings and redirect.
        if (errors.isEmpty()) {
            JiveGlobals.setXMLProperty("ldap.usernameField", usernameField);
            if (searchFields != null) {
                JiveGlobals.setXMLProperty("ldap.searchFields", searchFields);
            }
            if (searchFilter != null) {
                JiveGlobals.setXMLProperty("ldap.searchFilter", searchFilter);
            }
            // Save vCard mappings
            vcardBean.saveXMLProperties();

            // Enable the LDAP auth and user providers. The group provider will be enabled on the next step.
            JiveGlobals.setXMLProperty("provider.user.className",
                    "org.jivesoftware.wildfire.ldap.LdapUserProvider");
            JiveGlobals.setXMLProperty("provider.auth.className",
                    "org.jivesoftware.wildfire.ldap.LdapAuthProvider");

            // Redirect
            response.sendRedirect("setup-ldap-group.jsp?serverType=" + serverType);
            return;
        }
    }
%>
<html>
<head>
    <title><fmt:message key="setup.ldap.title" /></title>
    <meta name="currentStep" content="3"/>

</head>

<body>

	<h1><fmt:message key="setup.ldap.profile" />: <span><fmt:message key="setup.ldap.user_mapping" /></h1>

	<!-- BEGIN jive-contentBox_stepbar -->
	<div id="jive-contentBox_stepbar">
		<span class="jive-stepbar_step"><em>1. <fmt:message key="setup.ldap.connection_settings" /></em></span>
		<span class="jive-stepbar_step"><strong>2. <fmt:message key="setup.ldap.user_mapping" /></strong></span>
		<span class="jive-stepbar_step"><em>3. <fmt:message key="setup.ldap.group_mapping" /></em></span>
	</div>
	<!-- END jive-contentBox-stepbar -->

	<!-- BEGIN jive-contentBox -->
	<div class="jive-contentBox jive-contentBox_for-stepbar">

	<h2><fmt:message key="setup.ldap.step_two" />: <span><fmt:message key="setup.ldap.user_mapping" /></span></h2>
	<p><fmt:message key="setup.ldap.user.description" /></p>

    <%  if (errors.size() > 0) { %>

    <div class="error">
        <% for (String error:errors.values()) { %>
            <%= error%><br/>
        <% } %>
    </div>

    <%  } %>

    <form action="setup-ldap-user.jsp" method="post">
		<input type="hidden" name="serverType" value="<%=serverType%>">
        <!-- BEGIN jive-contentBox_bluebox -->
		<div class="jive-contentBox_bluebox">

			<table border="0" cellpadding="0" cellspacing="2">
			<tr>
			<td colspan="2"><strong><fmt:message key="setup.ldap.user_mapping" /></strong></td>
			</tr>
			<tr>
			<td align="right"><fmt:message key="setup.ldap.user.username_field" />:</td>
			<td><input type="text" name="usernameField" id="jiveLDAPusername" size="22" maxlength="40" value="<%= usernameField!=null?usernameField:""%>"><span class="jive-setup-helpicon" onmouseover="domTT_activate(this, event, 'content', '<fmt:message key="setup.ldap.user.username_field_description" />', 'styleClass', 'jiveTooltip', 'trail', true, 'delay', 300, 'lifetime', -1);"></span></td>
			</tr>
			</table>

			<!-- BEGIN jiveAdvancedButton -->
			<div class="jiveAdvancedButton jiveAdvancedButtonTopPad">
				<a href="#" onclick="togglePanel(jiveAdvanced); return false;" id="jiveAdvancedLink"><fmt:message key="setup.ldap.advanced" /></a>
			</div>
			<!-- END jiveAdvancedButton -->

			<!-- BEGIN jiveAdvancedPanelu (advanced user mapping settings) -->
				<div class="jiveadvancedPanelu" id="jiveAdvanced" style="display: none;">
					<div>
						<table border="0" cellpadding="0" cellspacing="2">
						<tr>
						<td align="right"><fmt:message key="setup.ldap.user.search_fields" />:</td>
						<td><input type="text" name="searchFields" value="<%= searchFields!=null?searchFields:""%>" id="jiveLDAPsearchfields" size="40" maxlength="100"><span class="jive-setup-helpicon" onmouseover="domTT_activate(this, event, 'content', '<fmt:message key="setup.ldap.user.search_fields_description" />', 'styleClass', 'jiveTooltip', 'trail', true, 'delay', 300, 'lifetime', -1);"></span></td>
						</tr>
						<tr>
						<td align="right"><fmt:message key="setup.ldap.user.user_filter" />:</td>
						<td><input type="text" name="searchFilter" value="<%= searchFilter!=null?searchFilter:""%>" id="jiveLDAPsearchfilter" size="40" maxlength="100"><span class="jive-setup-helpicon" onmouseover="domTT_activate(this, event, 'content', '<fmt:message key="setup.ldap.user.user_filter_description" />', 'styleClass', 'jiveTooltip', 'trail', true, 'delay', 300, 'lifetime', -1);"></span></td>
						</tr>
						</table>
					</div>
				</div>
			<!-- END jiveAdvancedPanelu (advanced user mapping settings) -->

		</div>
		<!-- END jive-contentBox_bluebox -->


		<script type="text/javascript" language="JavaScript">
			function jiveRowHighlight(theInput) {

				var e = $(jivevCardTable).getElementsByTagName('tr');
					for (var i = 0; i < e.length; i++) {
							e[i].style.backgroundColor = "#fff";
					}

				theInput.parentNode.parentNode.style.backgroundColor = "#eaeff4";
			}

		</script>
		<!-- BEGIN jive-contentBox_greybox -->
		<div class="jive-contentBox_greybox">
			<strong>User Profiles (vCard)</strong>
			<p>Lorem ipsum some sentance describing what all the fields below are, etc.</p>

			<!-- BEGIN vcard table -->
			<table border="0" cellpadding="0" cellspacing="1" class="jive-vcardTable" id="jivevCardTable">
				<thead>
				<tr>
					<th width="40%">Profile Field</th>
					<th width="60%">Value</th>
				</tr>
				</thead>
				<tbody>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						<strong>Name</strong>
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="name" value="<%= vcardBean.getName() %>" id="name" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						<strong>Email</strong>
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="email" value="<%= vcardBean.getEmail() %>" id="email" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						&nbsp;
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						&nbsp;
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						<strong>Full Name</strong>
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="fullname" value="<%= vcardBean.getFullName() %>" id="fullName" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						<strong>Nickname</strong>
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="nickname" value="<%= vcardBean.getNickname() %>" id="nickname" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						<strong>Birthday</strong>
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="dob" value="<%= vcardBean.getBirthday() %>" id="birthday" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						<strong>Home</strong>
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						&nbsp;
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Street Address
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="homestreet" value="<%= vcardBean.getHome_street() %>" id="home_street" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- City
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="homecity" value="<%= vcardBean.getHome_city() %>" id="home_city" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- State/Province
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="homestate" value="<%= vcardBean.getHome_state() %>" id="home_state" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Postal Code
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="homezip" value="<%= vcardBean.getHome_zip() %>" id="home_zip" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Country
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="homecountry" value="<%= vcardBean.getHome_country() %>" id="home_country" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Phone Number
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="homephone" value="<%= vcardBean.getHome_phone() %>" id="home_phone" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Mobile Number
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="homemobile" value="<%= vcardBean.getHome_mobile() %>" id="home_mobile" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Fax
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="homefax" value="<%= vcardBean.getHome_fax() %>" id="home_fax" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Pager
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="homepager" value="<%= vcardBean.getHome_pager() %>" id="home_pager" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						<strong>Business</strong>
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						&nbsp;
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Street Address
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="workstreet" value="<%= vcardBean.getBusiness_street() %>" id="business_street" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- City
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="workcity" value="<%= vcardBean.getBusiness_city() %>" id="business_city" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- State/Province
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="workstate" value="<%= vcardBean.getBusiness_state() %>" id="business_state" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Postal Code
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="workzip" value="<%= vcardBean.getBusiness_zip() %>" id="business_zip" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Country
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="workcountry" value="<%= vcardBean.getBusiness_country() %>" id="business_country" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Job Title
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="worktitle" value="<%= vcardBean.getBusiness_job_title() %>" id="business_job_title" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Department
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="workdept" value="<%= vcardBean.getBusiness_department() %>" id="business_department" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Phone Number
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="workphone" value="<%= vcardBean.getBusiness_phone() %>" id="business_phone" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Mobile Number
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="workmobile" value="<%= vcardBean.getBusiness_mobile() %>" id="business_mobile" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Fax
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="workfax" value="<%= vcardBean.getBusiness_fax() %>" id="business_fax" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderBottom jive-vardBorderRight" nowrap>
						- Pager
					</td>
					<td class="jive-vcardTable-value jive-vardBorderBottom">
						<input type="text" name="workpager" value="<%= vcardBean.getBusiness_pager() %>" id="business_pager" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
				<tr>
					<td class="jive-vcardTable-label jive-vardBorderRight" nowrap>
						- Web page
					</td>
					<td class="jive-vcardTable-value">
						<input type="text" name="workurl" value="<%= vcardBean.getBusiness_web_page() %>" id="business_web_page" size="22" maxlength="50" onFocus="jiveRowHighlight(this);">
					</td>
				</tr>
			</table>
			<!-- END vcard table -->

		</div>
		<!-- END jive-contentBox_greybox -->

		<!-- BEGIN jive-buttons -->
		<div class="jive-buttons">

			<!-- BEGIN right-aligned buttons -->
			<div align="right">
				<%--<a href="setup-ldap-user_test.jsp" class="lbOn" id="jive-setup-test2">
				<img src="../images/setup_btn_gearplay.gif" alt="" width="14" height="14" border="0">
				<fmt:message key="setup.ldap.test" />
				</a>--%>

				<input type="Submit" name="save" value="<fmt:message key="setup.ldap.continue" />" id="jive-setup-save" border="0">
			</div>
			<!-- END right-aligned buttons -->

		</div>
		<!-- END jive-buttons -->

	</form>

	</div>
	<!-- END jive-contentBox -->



</body>
</html>
